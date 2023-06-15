
codeunit 50151 Generate_EWayBill_SalesInvoice
{
    trigger OnRun()
    begin

    end;

    var
        i: Integer;
        JObject: DotNet JObject;
        JsonWriter: DotNet JsonTextWriter;

        GlobalNull: Variant;

    procedure GenerateEwayBill(SalesInvHeader: Record "Sales Invoice Header")
    var
        recSalesInvLine: Record "Sales Invoice Line";
        jsonString: text;
        recCust: Record Customer;
        authToken: text;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
        jsonObjectlinq: DotNet JObject;
        pg_SalesInvoice_POst: Page "Posted Sales Invoice";
        txtDecryptedSek: text;
        finalPayload: text;
        GSTInv_DLL: DotNet GSTEncr_Decr1;
        encryptedIRNPayload: text;
        jsonwriter1: DotNet JsonTextWriter;
    begin
        recCust.get(SalesInvHeader."Sell-to Customer No.");
        if recCust."GST Customer Type" in [recCust."GST Customer Type"::Unregistered, recCust."GST Customer Type"::" "] then
            Error('E-Way bill generation not applicable for the customer type');

        recSalesInvLine.Reset();
        recSalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        recSalesInvLine.SetFilter(Type, '=%1|%2', recSalesInvLine.Type::Item, recSalesInvLine.Type::"Charge (Item)");
        // recSalesInvLine.SetFilter(Type, '=%1', recSalesInvLine.Type::"Charge (Item)");
        if not recSalesInvLine.Find('-') then
            exit;

        clear(GlobalNull);
        jsonString := writeJsonPayload(SalesInvHeader);
        Message(jsonString);

        CU_SalesInvoice.GenerateAuthToken(SalesInvHeader);
        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, SalesInvHeader."No.");
        if recAuthData.Findlast() then begin
            txtDecryptedSek := recAuthData.DecryptedSEK;

            GSTInv_DLL := GSTInv_DLL.RSA_AES();
            encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

            jsonObjectlinq := jsonObjectlinq.JObject();
            jsonwriter1 := jsonObjectlinq.CreateWriter();

            jsonwriter1.WritePropertyName('Data');
            jsonwriter1.WriteValue(encryptedIRNPayload);
            // Message(encryptedIRNPayload);

            finalPayload := jsonObjectlinq.ToString();
            // Message('FinalIRNPayload %1 ', finalPayload);
            CU_SalesInvoice.Call_IRN_API(recAuthData, finalPayload, false, SalesInvHeader, true, false);
        end;


    end;

    procedure CancelEWayBill(recSalesInvoiceHeader: Record "Sales Invoice Header")
    var
        JsonObj1: DotNet JObject;
        jsonString: text;
        jsonObjectlinq: DotNet JObject;
        CU_SalesE_Invoice: Codeunit E_Invoice_SalesInvoice;
        GSTInv_DLL: DotNet GSTEncr_Decr1;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        encryptedIRNPayload: text;
        txtDecryptedSek: text;
        finalPayload: text;
        JsonWriter1: DotNet JsonTextWriter;
        jsonWriter2: DotNet JsonTextWriter;
        codeReason: code[2];
    begin
        JsonObj1 := JsonObj1.JObject();
        JsonWriter1 := JsonObj1.CreateWriter();

        JsonWriter1.WritePropertyName('ewbNo');
        if recSalesInvoiceHeader."E-Way Bill No." = '' then
            Error('E-Way bill not generated yet. Cancellation can''t be done')
        else
            JsonWriter1.WriteValue(recSalesInvoiceHeader."E-Way Bill No.");

        JsonWriter1.WritePropertyName('cancelRsnCode');

        Case recSalesInvoiceHeader."E-Way Bill Cancel Reason" of
            recSalesInvoiceHeader."E-Way Bill Cancel Reason"::"Duplicate Order":
                codeReason := '1';
            recSalesInvoiceHeader."E-Way Bill Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recSalesInvoiceHeader."E-Way Bill Cancel Reason"::"Order Cancelled":
                codeReason := '3';
            recSalesInvoiceHeader."E-Way Bill Cancel Reason"::Other:
                codeReason := '4';
        end;
        JsonWriter1.WriteValue(codeReason);

        JsonWriter1.WritePropertyName('cancelRmrk');
        JsonWriter1.WriteValue(recSalesInvoiceHeader."E-Way Bill Cancel Remarks");

        jsonString := JsonObj1.ToString();

        CU_SalesE_Invoice.GenerateAuthToken(recSalesInvoiceHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, recSalesInvoiceHeader."No.");
        if recAuthData.Findlast() then begin

            txtDecryptedSek := recAuthData.DecryptedSEK;

            Message(jsonString);

            GSTInv_DLL := GSTInv_DLL.RSA_AES();
            // base64IRN := CU_Base64.ToBase64(JsonText);
            encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

            jsonObjectlinq := jsonObjectlinq.JObject();
            jsonWriter2 := jsonObjectlinq.CreateWriter();

            jsonWriter2.WritePropertyName('action');
            jsonWriter2.WriteValue('CANEWB');

            jsonWriter2.WritePropertyName('Data');
            jsonWriter2.WriteValue(encryptedIRNPayload);

            finalPayload := jsonObjectlinq.ToString();
            // Message('FinalIRNPayload %1 ', finalPayload);
            CU_SalesE_Invoice.Call_IRN_API(recAuthData, finalPayload, false, recSalesInvoiceHeader, false, true);
        end;

    end;


    procedure UpdateEWayCancelHeader(txtEwayNum: text; txtEWayCancelDt: Text; SalesInvHeader: Record "Sales Invoice Header")
    var
        recSIHeader: Record "Sales Invoice Header";
        CUSIEINvoice: Codeunit E_Invoice_SalesInvoice;
        txtCancelDT: text;

    begin
        recSIHeader.get(SalesInvHeader."No.");
        recSIHeader."E-Way Bill No." := txtEwayNum;
        // txtCancelDT := CUSIEINvoice.ConvertAckDt(txtEWayCancelDt);
        recSIHeader."E-Way Bill Cancel Date" := txtEWayCancelDt;
        recSIHeader.Modify();
    end;

    procedure writeJsonPayload(SalesInvHeader: Record "Sales Invoice Header"): text;
    var
        intDistance: Integer;
        jsonString: text;

        recCstomer: Record Customer;
        recLocation: Record Location;
        Pin: integer;
        StateBuff: Record State;
        shipCode: code[2];
        shipmentMethod: Code[10];
        recShipMethod: Record "Shipment Method";

    begin
        recLocation.Get(SalesInvHeader."Location Code");

        JObject := JObject.JObject();
        JsonWriter := JObject.CreateWriter();

        JsonWriter.WritePropertyName('Irn');
        if SalesInvHeader."IRN Hash" = '' then
            Error('E-Way Bill generation can only be done after E-Invoice ')
        else
            JsonWriter.WriteValue(SalesInvHeader."IRN Hash");

        // intDistance := 0;
        if SalesInvHeader."Distance (Km)" > 4000 then
            Error('Max. allowed disctance is 4000 as per GST Portal!');

        JsonWriter.WritePropertyName('Distance');
        if SalesInvHeader."Bill-to Post Code" <> SalesInvHeader."Sell-to Post Code" then
            JsonWriter.WriteValue(0)//Auto calculation by GST Portal
        else begin
            intDistance := SalesInvHeader."Distance (Km)";
            JsonWriter.WriteValue(intDistance);
        end;
        // JsonWriter.WriteValue(0);
        // //     if intDistance = 0 then
        //         Error('Distance cannot be 0 for Transactions having same Origin and Destination PIN codes!!');
        // recShipMethod.Get(SalesInvHeader."Shipment Method Code");
        shipmentMethod := LowerCase(SalesInvHeader."Shipment Method Code");
        JsonWriter.WritePropertyName('TransMode');
        case   //standard GST Codes as per Json Schem per NIC
            shipmentMethod of
            'road':
                shipCode := '1';
            'ship':
                shipCode := '3';
            'air':
                shipCode := '4';
            'rail':
                shipCode := '2';
        end;
        JsonWriter.WriteValue(shipCode);
        // JsonWriter.WriteValue(recShipMethod."GST Trans Mode");

        // if SalesInvHeader."Mode of Transport" = 'ODC'
        // then
        //     JsonWriter.WriteValue('O')
        // else
        //     JsonWriter.WriteValue('R');

        // recShipMethod.Get(SalesInvHeader."Shipment Method Code");
        JsonWriter.WritePropertyName('TransId');
        // JsonWriter.WriteValue(recShipMethod."GST Trans Mode");
        JsonWriter.WriteValue(recLocation."GST Registration No.");
        // JsonWriter.WriteValue(SalesInvHeader."Shipment Method Code");

        JsonWriter.WritePropertyName('TransName');
        JsonWriter.WriteValue(SalesInvHeader."Shipping Agent Code");

        JsonWriter.WritePropertyName('TransDocDt');
        JsonWriter.WriteValue(format(SalesInvHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));

        JsonWriter.WritePropertyName('TransDocNo');
        JsonWriter.WriteValue(SalesInvHeader."LR/RR No.");

        JsonWriter.WritePropertyName('VehNo');
        JsonWriter.WriteValue(SalesInvHeader."Vehicle No.");

        JsonWriter.WritePropertyName('VehType');
        if SalesInvHeader."Mode of Transport" = 'ODC'
        then
            JsonWriter.WriteValue('O')
        else
            JsonWriter.WriteValue('R');
        // JsonWriter.WriteValue(format(SalesInvHeader."Vehicle Type"));
        // recShipMethod.Get(SalesInvHeader."Shipment Method Code");
        // JsonWriter.WriteValue(recShipMethod."GST Trans Mode");

        recLocation.get(SalesInvHeader."Location Code");

        /*JsonWriter.WritePropertyName('ExpShipDtls');
        JsonWriter.WriteStartObject();

        JsonWriter.WritePropertyName('Addr1');
        JsonWriter.WriteValue(copystr(recLocation.Address, 1, 50));

        JsonWriter.WritePropertyName('Addr2');
        JsonWriter.WriteValue(copystr(recLocation."Address 2", 1, 50));

        JsonWriter.WritePropertyName('Loc');
        JsonWriter.WriteValue(recLocation.City);

        EVALUATE(Pin, COPYSTR(recLocation."Post Code", 1, 6));
        StateBuff.GET(recLocation."State Code");

        JsonWriter.WritePropertyName('Pin');
        JsonWriter.WriteValue(Pin);

        JsonWriter.WritePropertyName('Stcd');
        JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");

        JsonWriter.WriteEndObject();
        */

        jsonString := JObject.ToString();
        exit(jsonString);
    end;

    procedure UpdateHeaderIRN(EwayBillDt: Text; EwayBillNum: text; EwayBillValid: Text; SalesInvHeader: Record "Sales Invoice Header")
    var
        FieldRef1: FieldRef;
        RecRef1: RecordRef;
        dtText: text;
        inStr: InStream;
        ValidDate: DateTime;
        IBarCodeProvider: DotNet BarcodeProvider;
        BillDate: DateTime;
        blobCU: Codeunit "Temp Blob";
        CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
        FileManagement: Codeunit "File Management";
        recSIHeader: Record "Sales Invoice Header";
    begin
        RecRef1.OPEN(112);
        FieldRef1 := RecRef1.FIELD(3);
        FieldRef1.SETRANGE(SalesInvHeader."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN

            dtText := CU_SalesInvoice.ConvertAckDt(EwayBillDt);
            Evaluate(BillDate, dtText);
            FieldRef1 := RecRef1.FIELD(recSIHeader.FieldNo("E-Way Bill Date"));
            FieldRef1.VALUE := BillDate;
            // FieldRef1 := RecRef1.FIELD(50001);//AckNum

            FieldRef1 := RecRef1.FIELD(recSIHeader.FieldNo("E-Way Bill No."));
            FieldRef1.VALUE := EwayBillNum;

            dtText := CU_SalesInvoice.ConvertAckDt(EwayBillValid);
            EVALUATE(ValidDate, dtText);
            FieldRef1 := RecRef1.FIELD(recSIHeader.FieldNo("E-Way Bill Valid Upto"));
            FieldRef1.VALUE := ValidDate;
            RecRef1.MODIFY;
        END;
        // Erase the temporary file.
    end;
}