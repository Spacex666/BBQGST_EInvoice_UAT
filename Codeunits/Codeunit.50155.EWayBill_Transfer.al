codeunit 50155 E_WayBill_Transfer
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        JObject: DotNet JObject;
        JsonWriter: DotNet JsonTextWriter;
        jsonString: text;
        CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
        CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
        GlobalNull: Variant;


    procedure GenerateEwaybllWithoutIRN(TransferShipHeader: Record "Transfer Shipment Header")
    var
        recAuthData: Record "GST E-Invoice(Auth Data)";
        txtDecryptedSek: text;
        jsonwriter1: DotNet JsonTextWriter;
        jsonObjectlinq: DotNet JObject;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        finalPayload: text;
        encryptedIRNPayload: Text;
    begin
        if TransferShipHeader."E-Way Bill No." <> '' then
            Error('Already Generated');
        clear(GlobalNull);
        jsonString := WriteEWayWihtoutIRNPayload(TransferShipHeader);
        Message(jsonString);
        // WriteEWayWihtoutIRNPayload(TransferShipHeader)
        recAuthData.Reset();
        if recAuthData.Findlast() then begin
            if (recAuthData."Auth Token" <> '') and ((Time > recAuthData."Token Duration") and (recAuthData."Expiry Date" >= Today)) then
                CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader)
            else
                if (recAuthData."Expiry Date" < Today) then
                    CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader)
        end else
            // if (recAuthData."Auth Token" = '') then
            CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader);
        recAuthData.Reset();
        if recAuthData.Findlast() then begin

            txtDecryptedSek := recAuthData.DecryptedSEK;
            GSTInv_DLL := GSTInv_DLL.RSA_AES();
            encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

            jsonObjectlinq := jsonObjectlinq.JObject();
            jsonwriter1 := jsonObjectlinq.CreateWriter();
            jsonWriter1.WritePropertyName('action');
            jsonWriter1.WriteValue('GENEWAYBILL');

            jsonwriter1.WritePropertyName('data');
            jsonwriter1.WriteValue(encryptedIRNPayload);
            // Message(encryptedIRNPayload);

            finalPayload := jsonObjectlinq.ToString();
            // Message((finalPayload));

            CU_TransferEInvoice.Call_Ewaybill_API(recAuthData, finalPayload, TransferShipHeader, true, false, false);
        end;
    end;




    procedure GenerateEwayBill(TransferShipHeader: Record "Transfer Shipment Header")
    var
        recAuthData: Record "GST E-Invoice(Auth Data)";
        txtDecryptedSek: text;
        jsonwriter1: DotNet JsonTextWriter;
        jsonObjectlinq: DotNet JObject;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        finalPayload: text;
        encryptedIRNPayload: Text;
    begin

        clear(GlobalNull);
        jsonString := writeJsonPayload(TransferShipHeader);
        Message(jsonString);

        // CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader);
        recAuthData.Reset();
        if recAuthData.Findlast() then begin
            if (recAuthData."Auth Token" <> '') and ((Time > recAuthData."Token Duration") and (recAuthData."Expiry Date" >= Today)) then
                CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader)
            else
                if (recAuthData."Expiry Date" < Today) then
                    CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader)
        end else
            // if (recAuthData."Auth Token" = '') then
            CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader);
        recAuthData.Reset();
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
            CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, TransferShipHeader, true, false);
            // end;

        end;

    end;


    procedure WriteEWayWihtoutIRNPayload(TransferShipHeader: Record "Transfer Shipment Header"): Text
    var
        intDistance: Integer;
        jsonString: text;
        recShipMethod: Record "Shipment Method";
        recCstomer: Record Customer;
        recLocation: Record Location;
        Pin: integer;
        StateBuff: Record State;
        shipCode: code[2];
        shipmentMethod: Code[10];
        TransferShipmentLine: Record "Transfer Shipment Line";
        recTolocation: Record Location;
        recUOM: Record "Unit of Measure";

    begin
        recLocation.get(TransferShipHeader."Transfer-from Code");
        recTolocation.get(TransferShipHeader."Transfer-to Code");
        if recLocation."State Code" <> recTolocation."State Code" then
            Error('Use EwayBill Using IRN');
        JObject := JObject.JObject();
        JsonWriter := JObject.CreateWriter();

        JsonWriter.WritePropertyName('supplyType');//'O','I'  Mandatory
        JsonWriter.WriteValue('O');

        JsonWriter.WritePropertyName('subSupplyType');  //Mandatory
        JsonWriter.WriteValue('8');

        JsonWriter.WritePropertyName('subSupplyDesc');
        JsonWriter.WriteValue('Branch Transfer');

        JsonWriter.WritePropertyName('docType');//"INV", "CHL", "BIL","BOE","OTH" 
        JsonWriter.WriteValue('CHL');

        JsonWriter.WritePropertyName('docNo');   //Mandatory
        JsonWriter.WriteValue(Format((TransferShipHeader."No.")));

        JsonWriter.WritePropertyName('docDate');// dd/mm/yyyy   //Mandatory
        JsonWriter.WriteValue(format(TransferShipHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

        JsonWriter.WritePropertyName('fromGstin');  //Mandatory
        recLocation.Get(TransferShipHeader."Transfer-from Code");
        JsonWriter.WriteValue(recLocation."GST Registration No.");

        JsonWriter.WritePropertyName('fromTrdName');   //Mandatory
        JsonWriter.WriteValue(recLocation.Name);

        JsonWriter.WritePropertyName('fromAddr1');
        JsonWriter.WriteValue(recLocation.Address);

        JsonWriter.WritePropertyName('fromAddr2');
        JsonWriter.WriteValue(recLocation."Address 2");

        JsonWriter.WritePropertyName('fromPlace');
        JsonWriter.WriteValue(recLocation.City);//Naveen

        JsonWriter.WritePropertyName('fromPincode');   //Mandatory
        JsonWriter.WriteValue(recLocation."Post Code");
        StateBuff.GET(recLocation."State Code");
        JsonWriter.WritePropertyName('actFromStateCode');   //Mandatory

        JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");//Naveen
        JsonWriter.WritePropertyName('fromStateCode');   //Mandatory
        JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");
        JsonWriter.WritePropertyName('toGstin');  //Mandatory
        recLocation.Get(TransferShipHeader."Transfer-to Code");
        JsonWriter.WriteValue(recLocation."GST Registration No.");
        JsonWriter.WritePropertyName('toTrdName');
        JsonWriter.WriteValue(recLocation.Name);
        JsonWriter.WritePropertyName('toAddr1');
        JsonWriter.WriteValue(recLocation.Address);
        JsonWriter.WritePropertyName('toAddr2');
        JsonWriter.WriteValue(recLocation."Address 2");
        JsonWriter.WritePropertyName('toPlace');
        JsonWriter.WriteValue(recLocation.City);
        JsonWriter.WritePropertyName('toPincode');   //Mandatory
        JsonWriter.WriteValue(recLocation."Post Code");
        StateBuff.GET(recLocation."State Code");
        JsonWriter.WritePropertyName('actToStateCode');   //Mandatory
        JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");//Naveen

        JsonWriter.WritePropertyName('toStateCode');
        //Mandatory

        JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");//Naveen
        JsonWriter.WritePropertyName('transactionType');//integer   //Mandatory
        JsonWriter.WriteValue(1);//1 regular 2 - Bill/Ship To  3 Bill/Dispatch From 
        JsonWriter.WritePropertyName('otherValue');
        JsonWriter.WriteValue('0');//Naveen--other value
        JsonWriter.WritePropertyName('totalValue');   //Mandatory
        TransferShipmentLine.Reset();
        TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
        TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
        IF TransferShipmentLine.FINDSET THEN BEGIN
            TransferShipmentLine.CalcSums(Amount);
        end;
        JsonWriter.WriteValue(TransferShipmentLine.Amount);
        JsonWriter.WritePropertyName('cgstValue');
        JsonWriter.WriteValue(0);
        JsonWriter.WritePropertyName('sgstValue');
        JsonWriter.WriteValue(0);
        JsonWriter.WritePropertyName('igstValue');
        JsonWriter.WriteValue(0);
        JsonWriter.WritePropertyName('cessValue');
        JsonWriter.WriteValue(0);
        JsonWriter.WritePropertyName('cessNonAdvolValue');
        JsonWriter.WriteValue(0);
        JsonWriter.WritePropertyName('totInvValue');
        JsonWriter.WriteValue(TransferShipmentLine.Amount);

        JsonWriter.WritePropertyName('transDistance');
        if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then
            JsonWriter.WriteValue(0)//Auto calculation by GST Portal
        else begin
            intDistance := TransferShipHeader."Distance (Km)";
            JsonWriter.WriteValue(intDistance);
        end;

        // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
        shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");


        recLocation.get(TransferShipHeader."Transfer-from Code");
        JsonWriter.WritePropertyName('transporterId');
        JsonWriter.WriteValue(recLocation."GST Registration No.");
        JsonWriter.WritePropertyName('transporterName');
        JsonWriter.WriteValue(TransferShipHeader."Shipping Agent Code");
        JsonWriter.WritePropertyName('transDocNo');
        JsonWriter.WriteValue(TransferShipHeader."LR/RR No.");
        JsonWriter.WritePropertyName('transMode');
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
        JsonWriter.WritePropertyName('transDocDate');
        JsonWriter.WriteValue(format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));
        JsonWriter.WritePropertyName('vehicleNo');
        JsonWriter.WriteValue(TransferShipHeader."Vehicle No.");
        JsonWriter.WritePropertyName('vehicleType');//"1","2","3","4"],"description": "Mode of transport (Road-1, Rail-2, Air-3, Ship-4) 
        if TransferShipHeader."Mode of Transport" = 'ODC'
         then
            JsonWriter.WriteValue('O')
        else
            JsonWriter.WriteValue('R');
        //transfershipment line
        //item details start
        TransferShipmentLine.Reset();
        TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
        TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
        IF TransferShipmentLine.FINDSET THEN BEGIN
            IF TransferShipmentLine.COUNT > 100 THEN
                ERROR('E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', TransferShipmentLine.COUNT);
            JsonWriter.WritePropertyName('itemList');   //Mandatory
            JsonWriter.WriteStartArray();
            repeat
                JsonWriter.WriteStartObject();
                JsonWriter.WritePropertyName('productName');
                JsonWriter.WriteValue(TransferShipmentLine."Item No.");
                JsonWriter.WritePropertyName('productDesc');
                JsonWriter.WriteValue(TransferShipmentLine.Description);
                JsonWriter.WritePropertyName('hsnCode');
                JsonWriter.WriteValue(TransferShipmentLine."HSN/SAC Code");
                JsonWriter.WritePropertyName('quantity');
                JsonWriter.WriteValue(TransferShipmentLine.Quantity);
                JsonWriter.WritePropertyName('qtyUnit');
                recUOM.Get(TransferShipmentLine."Unit of Measure Code");
                if recUOM."E-Inv UOM" = '' then Error('Please map E-Invoice UOM in UOM master !');
                //JsonWriter.WritePropertyName('Unit');
                JsonWriter.WriteValue(recUOM."E-Inv UOM");
                //Naveen
                JsonWriter.WritePropertyName('cgstRate');
                JsonWriter.WriteValue(0);
                JsonWriter.WritePropertyName('sgstRate');
                JsonWriter.WriteValue(0);
                JsonWriter.WritePropertyName('igstRate');
                JsonWriter.WriteValue(0);
                JsonWriter.WritePropertyName('cessRate');
                JsonWriter.WriteValue(0);
                JsonWriter.WritePropertyName('cessNonadvol');
                JsonWriter.WriteValue(0);
                JsonWriter.WritePropertyName('taxableAmount');
                JsonWriter.WriteValue(TransferShipmentLine.Amount);
                JsonWriter.WriteEndObject();
            until TransferShipmentLine.Next() = 0;
            JsonWriter.WriteEndArray();
            //item details end
            jsonString := JObject.ToString();

        end;
        exit(jsonString);
    end;

    procedure ConvertAckDt_EWB(DtText: text): text;
    var
        DateTime_Fin: text;
        YYYY: text;
        DD: text;
        MM: text;
    begin
        YYYY := COPYSTR(DtText, 7, 4);
        MM := COPYSTR(DtText, 4, 2);
        DD := COPYSTR(DtText, 1, 2); // CCIT AN  Generate Wrong EWAYbill Date


        //erroneous code CITS_RS commented 140623
        // DD := CopyStr(DtText, 1, 2);
        // MM := CopyStr(DtText, 4, 2);
        // YYYY := CopyStr(DtText, 7, 4);//New Added CCIT AN 13062023

        // TIME := COPYSTR(AckDt2,12,8);

        DateTime_Fin := DD + '/' + MM + '/' + YYYY + ' ' + COPYSTR(DtText, 12, 6);
        // DateTime_Fin := MM + '/' + DD + '/' + YYYY + ' ' + COPYSTR(DtText, 12, 8);
        exit(DateTime_Fin);
    end;

    procedure writeJsonPayload(TransferShipHeader: Record "Transfer Shipment Header"): text;
    var
        intDistance: Integer;
        jsonString: text;
        recShipMethod: Record "Shipment Method";
        recCstomer: Record Customer;
        recLocation: Record Location;
        Pin: integer;
        StateBuff: Record State;
        shipCode: code[2];
        shipmentMethod: Code[10];

    begin
        recLocation.get(TransferShipHeader."Transfer-from Code");
        JObject := JObject.JObject();
        JsonWriter := JObject.CreateWriter();

        JsonWriter.WritePropertyName('Irn');
        if TransferShipHeader."Irn No." = '' then
            Error('E-Way Bill generation can only be done after E-Invoice ')
        else
            JsonWriter.WriteValue(TransferShipHeader."Irn No.");

        // intDistance := 0;
        // if TransferShipHeader."Transfer-from Code" = TransferShipHeader."Transfer-to Code" then
        //     if intDistance = 0 then
        //         Error('Distance cannot be 0 for Transactions having same Origin and Destination PIN codes!!');
        if TransferShipHeader."Distance (Km)" > 4000 then
            Error('Max. allowed disctance is 4000 as per GST Portal!');

        JsonWriter.WritePropertyName('Distance');
        if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then
            JsonWriter.WriteValue(0)//Auto calculation by GST Portal
        else begin
            intDistance := TransferShipHeader."Distance (Km)";
            JsonWriter.WriteValue(intDistance);
        end;

        // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
        shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");
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
        // JsonWriter.WriteValue(TransferShipHeader."Mode of Transport");


        JsonWriter.WritePropertyName('TransId');
        JsonWriter.WriteValue(recLocation."GST Registration No.");


        JsonWriter.WritePropertyName('TransName');
        JsonWriter.WriteValue(TransferShipHeader."Shipping Agent Code");

        JsonWriter.WritePropertyName('TransDocDt');
        JsonWriter.WriteValue(format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));

        JsonWriter.WritePropertyName('TransDocNo');
        JsonWriter.WriteValue(TransferShipHeader."LR/RR No.");

        JsonWriter.WritePropertyName('VehNo');
        JsonWriter.WriteValue(TransferShipHeader."Vehicle No.");

        JsonWriter.WritePropertyName('VehType');
        if TransferShipHeader."Mode of Transport" = 'ODC'
        then
            JsonWriter.WriteValue('O')
        else
            JsonWriter.WriteValue('R');

        recLocation.get(TransferShipHeader."Transfer-from Code");

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

    procedure UpdateHeaderIRN(EwayBillDt: Text; EwayBillNum: text; EwayBillValid: Text; TransferShipHeader: Record "Transfer Shipment Header"; IntraState: Boolean)
    var
        FieldRef1: FieldRef;
        RecRef1: RecordRef;
        dtText: text;
        inStr: InStream;
        ValidDate: DateTime;
        BillDate: DateTime;
        blobCU: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        RecRef1.OPEN(5744);
        FieldRef1 := RecRef1.FIELD(1);
        FieldRef1.SETRANGE(TransferShipHeader."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN

            if IntraState then
                dtText := ConvertAckDt_EWB(EwayBillDt)
            else
                dtText := CU_SalesInvoice.ConvertAckDt(EwayBillDt);
            Evaluate(BillDate, dtText);

            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Date"));
            FieldRef1.VALUE := BillDate;

            // FieldRef1 := RecRef1.FIELD(50001);//AckNum

            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill No."));
            FieldRef1.VALUE := EwayBillNum;
            if EwayBillValid <> 'null' then begin
                if IntraState then
                    dtText := ConvertAckDt_EWB(EwayBillValid)
                else
                    CU_SalesInvoice.ConvertAckDt(EwayBillDt);
                EVALUATE(ValidDate, dtText);
            end
            else begin
                ValidDate := BillDate;
            end;
            FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Valid Upto"));
            FieldRef1.VALUE := ValidDate;
            RecRef1.MODIFY;
        END;
        // Erase the temporary file.
    end;

    procedure CancelEWayBill(recTransShipHeader: Record "Transfer Shipment Header")
    var
        JsonObj1: DotNet JObject;
        jsonString: text;
        jsonObjectlinq: DotNet JObject;
        CU_SalesE_Invoice: Codeunit E_Invoice_SalesInvoice;
        GSTInv_DLL: DotNet GSTEncr_Decr;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        encryptedIRNPayload: text;
        txtDecryptedSek: text;
        finalPayload: text;
        JsonWriter1: DotNet JsonTextWriter;
        CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
        jsonWriter2: DotNet JsonTextWriter;
        codeReason: code[2];
    begin
        JsonObj1 := JsonObj1.JObject();
        JsonWriter1 := JsonObj1.CreateWriter();

        JsonWriter1.WritePropertyName('ewbNo');
        if recTransShipHeader."E-Way Bill No." = '' then
            Error('E-Way bill not generated yet. Cancellation can''t be done')
        else
            JsonWriter1.WriteValue(recTransShipHeader."E-Way Bill No.");

        JsonWriter1.WritePropertyName('cancelRsnCode');

        Case recTransShipHeader."E-Way Cancel Reason" of
            recTransShipHeader."E-Way Cancel Reason"::"Duplicate Order":
                codeReason := '1';
            recTransShipHeader."E-Way Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recTransShipHeader."E-Way Cancel Reason"::"Order Cancelled":
                codeReason := '3';
            recTransShipHeader."E-Way Cancel Reason"::Other:
                codeReason := '4';
        end;
        JsonWriter1.WriteValue(codeReason);

        JsonWriter1.WritePropertyName('cancelRmrk');
        JsonWriter1.WriteValue(recTransShipHeader."E-Way Bill Cancel Remarks");

        jsonString := JsonObj1.ToString();

        CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

        // recAuthData.Reset();
        // recAuthData.SetRange(DocumentNum, recTransShipHeader."No.");//Document number is universal for all documents and both E-Invoice and E-Way Bill 250922
        // if recAuthData.Findlast() then begin
        recAuthData.Reset();
        if recAuthData.Findlast() then begin
            if (recAuthData."Auth Token" <> '') and ((Time > recAuthData."Token Duration") and (recAuthData."Expiry Date" >= Today)) then
                CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader)
            else
                if (recAuthData."Expiry Date" < Today) then
                    CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader);
        end else
            // if (recAuthData."Auth Token" = '') then
                CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader);
        recAuthData.Reset();
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
            CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, recTransShipHeader, false, true);
        end;

    end;


    procedure UpdateEWayCancelHeader(txtEwayNum: text; txtEWayCancelDt: Text; recTrShipHeader: Record "Transfer Shipment Header")
    var
        recTrShHeader: Record "Transfer Shipment Header";
        //  CUSIEINvoice: Codeunit E_Invoice_SalesInvoice;
        txtCancelDT: text;

    begin
        recTrShHeader.get(recTrShipHeader."No.");
        recTrShHeader."E-Way Bill No." := txtEwayNum;
        // txtCancelDT := CUSIEINvoice.ConvertAckDt(txtEWayCancelDt);
        recTrShHeader."E-Way Bill Cancel Date" := txtEWayCancelDt;
        recTrShHeader.Modify();
    end;

    procedure ParseResponse()
    var
    begin
    end;
}

