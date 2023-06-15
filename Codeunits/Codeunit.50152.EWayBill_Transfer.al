// codeunit 50152 E_WayBill_Transfer
// {
//     trigger OnRun()
//     begin

//     end;

//     var
//         myInt: Integer;
//         JObject: DotNet JObject;
//         JsonWriter: DotNet JsonTextWriter;

//         jsonString: text;

//         CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;

//         CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
//         GlobalNull: Variant;

//     procedure GenerateEwayBill(TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         txtDecryptedSek: text;
//         jsonwriter1: DotNet JsonTextWriter;
//         jsonObjectlinq: DotNet JObject;
//         GSTInv_DLL: DotNet GSTEncr_Decr1;
//         finalPayload: text;
//         encryptedIRNPayload: Text;
//     begin

//         clear(GlobalNull);
//         jsonString := writeJsonPayload(TransferShipHeader);
//         Message(jsonString);

//         CU_TransferEInvoice.GenerateAuthToken(TransferShipHeader);
//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, TransferShipHeader."No.");
//         if recAuthData.Findlast() then begin
//             txtDecryptedSek := recAuthData.DecryptedSEK;

//             GSTInv_DLL := GSTInv_DLL.RSA_AES();
//             encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

//             jsonObjectlinq := jsonObjectlinq.JObject();
//             jsonwriter1 := jsonObjectlinq.CreateWriter();

//             jsonwriter1.WritePropertyName('Data');
//             jsonwriter1.WriteValue(encryptedIRNPayload);
//             // Message(encryptedIRNPayload);

//             finalPayload := jsonObjectlinq.ToString();
//             // Message('FinalIRNPayload %1 ', finalPayload);
//             CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, TransferShipHeader, true, false);
//         end;

//     end;

//     procedure writeJsonPayload(TransferShipHeader: Record "Transfer Shipment Header"): text;
//     var
//         intDistance: Integer;
//         jsonString: text;
//         recShipMethod: Record "Shipment Method";
//         recCstomer: Record Customer;
//         recLocation: Record Location;
//         Pin: integer;
//         StateBuff: Record State;
//         shipCode: code[2];
//         shipmentMethod: Code[10];

//     begin
//         recLocation.get(TransferShipHeader."Transfer-from Code");
//         JObject := JObject.JObject();
//         JsonWriter := JObject.CreateWriter();

//         JsonWriter.WritePropertyName('Irn');
//         if TransferShipHeader."Irn No." = '' then
//             Error('E-Way Bill generation can only be done after E-Invoice ')
//         else
//             JsonWriter.WriteValue(TransferShipHeader."Irn No.");

//         // intDistance := 0;
//         // if TransferShipHeader."Transfer-from Code" = TransferShipHeader."Transfer-to Code" then
//         //     if intDistance = 0 then
//         //         Error('Distance cannot be 0 for Transactions having same Origin and Destination PIN codes!!');
//         if TransferShipHeader."Distance (Km)" > 4000 then
//             Error('Max. allowed disctance is 4000 as per GST Portal!');

//         JsonWriter.WritePropertyName('Distance');
//         if TransferShipHeader."Transfer-from Code" <> TransferShipHeader."Transfer-to Code" then
//             JsonWriter.WriteValue(0)//Auto calculation by GST Portal
//         else begin
//             intDistance := TransferShipHeader."Distance (Km)";
//             JsonWriter.WriteValue(intDistance);
//         end;

//         // recShipMethod.Get(TransferShipHeader."Shipment Method Code");
//         shipmentMethod := LowerCase(TransferShipHeader."Shipment Method Code");
//         JsonWriter.WritePropertyName('TransMode');
//         case   //standard GST Codes as per Json Schem per NIC
//             shipmentMethod of
//             'road':
//                 shipCode := '1';
//             'ship':
//                 shipCode := '3';
//             'air':
//                 shipCode := '4';
//             'rail':
//                 shipCode := '2';
//         end;
//         JsonWriter.WriteValue(shipCode);
//         // JsonWriter.WriteValue(recShipMethod."GST Trans Mode");
//         // JsonWriter.WriteValue(TransferShipHeader."Mode of Transport");


//         JsonWriter.WritePropertyName('TransId');
//         JsonWriter.WriteValue(recLocation."GST Registration No.");


//         JsonWriter.WritePropertyName('TransName');
//         JsonWriter.WriteValue(TransferShipHeader."Shipping Agent Code");

//         JsonWriter.WritePropertyName('TransDocDt');
//         JsonWriter.WriteValue(format(TransferShipHeader."LR/RR Date", 0, '<Day,2>/<Month,2>/<Year4>'));

//         JsonWriter.WritePropertyName('TransDocNo');
//         JsonWriter.WriteValue(TransferShipHeader."LR/RR No.");

//         JsonWriter.WritePropertyName('VehNo');
//         JsonWriter.WriteValue(TransferShipHeader."Vehicle No.");

//         JsonWriter.WritePropertyName('VehType');
//         if TransferShipHeader."Mode of Transport" = 'ODC'
//         then
//             JsonWriter.WriteValue('O')
//         else
//             JsonWriter.WriteValue('R');

//         recLocation.get(TransferShipHeader."Transfer-from Code");

//         /*JsonWriter.WritePropertyName('ExpShipDtls');
//         JsonWriter.WriteStartObject();

//         JsonWriter.WritePropertyName('Addr1');
//         JsonWriter.WriteValue(copystr(recLocation.Address, 1, 50));

//         JsonWriter.WritePropertyName('Addr2');
//         JsonWriter.WriteValue(copystr(recLocation."Address 2", 1, 50));

//         JsonWriter.WritePropertyName('Loc');
//         JsonWriter.WriteValue(recLocation.City);

//         EVALUATE(Pin, COPYSTR(recLocation."Post Code", 1, 6));
//         StateBuff.GET(recLocation."State Code");

//         JsonWriter.WritePropertyName('Pin');
//         JsonWriter.WriteValue(Pin);

//         JsonWriter.WritePropertyName('Stcd');
//         JsonWriter.WriteValue(StateBuff."State Code (GST Reg. No.)");

//         JsonWriter.WriteEndObject();
//         */

//         jsonString := JObject.ToString();
//         exit(jsonString);

//     end;

//     procedure UpdateHeaderIRN(EwayBillDt: Text; EwayBillNum: text; EwayBillValid: Text; TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         FieldRef1: FieldRef;
//         RecRef1: RecordRef;
//         dtText: text;
//         inStr: InStream;
//         ValidDate: DateTime;
//         IBarCodeProvider: DotNet BarcodeProvider;
//         BillDate: DateTime;
//         blobCU: Codeunit "Temp Blob";
//         FileManagement: Codeunit "File Management";
//     begin
//         RecRef1.OPEN(5744);
//         FieldRef1 := RecRef1.FIELD(1);
//         FieldRef1.SETRANGE(TransferShipHeader."No.");//Parameter
//         IF RecRef1.FINDFIRST THEN BEGIN

//             dtText := CU_SalesInvoice.ConvertAckDt(EwayBillDt);
//             Evaluate(BillDate, dtText);

//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Date"));
//             FieldRef1.VALUE := BillDate;
//             // FieldRef1 := RecRef1.FIELD(50001);//AckNum

//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill No."));
//             FieldRef1.VALUE := EwayBillNum;

//             dtText := CU_SalesInvoice.ConvertAckDt(EwayBillValid);
//             EVALUATE(ValidDate, dtText);
//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Valid Upto"));
//             FieldRef1.VALUE := ValidDate;
//             RecRef1.MODIFY;
//         END;
//         // Erase the temporary file.
//     end;

//     procedure CancelEWayBill(recTransShipHeader: Record "Transfer Shipment Header")
//     var
//         JsonObj1: DotNet JObject;
//         jsonString: text;
//         jsonObjectlinq: DotNet JObject;
//         CU_SalesE_Invoice: Codeunit E_Invoice_SalesInvoice;
//         GSTInv_DLL: DotNet GSTEncr_Decr1;
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         encryptedIRNPayload: text;
//         txtDecryptedSek: text;
//         finalPayload: text;
//         JsonWriter1: DotNet JsonTextWriter;
//         CU_TransferEInvoice: Codeunit E_Invoice_TransferShipments;
//         jsonWriter2: DotNet JsonTextWriter;
//         codeReason: code[2];
//     begin
//         JsonObj1 := JsonObj1.JObject();
//         JsonWriter1 := JsonObj1.CreateWriter();

//         JsonWriter1.WritePropertyName('ewbNo');
//         if recTransShipHeader."E-Way Bill No." = '' then
//             Error('E-Way bill not generated yet. Cancellation can''t be done')
//         else
//             JsonWriter1.WriteValue(recTransShipHeader."E-Way Bill No.");

//         JsonWriter1.WritePropertyName('cancelRsnCode');

//         Case recTransShipHeader."E-Way Cancel Reason" of
//             recTransShipHeader."E-Way Cancel Reason"::"Duplicate Order":
//                 codeReason := '1';
//             recTransShipHeader."E-Way Cancel Reason"::"Data Entry Mistake":
//                 codeReason := '2';
//             recTransShipHeader."E-Way Cancel Reason"::"Order Cancelled":
//                 codeReason := '3';
//             recTransShipHeader."E-Way Cancel Reason"::Other:
//                 codeReason := '4';
//         end;
//         JsonWriter1.WriteValue(codeReason);

//         JsonWriter1.WritePropertyName('cancelRmrk');
//         JsonWriter1.WriteValue(recTransShipHeader."E-Way Bill Cancel Remarks");

//         jsonString := JsonObj1.ToString();

//         CU_TransferEInvoice.GenerateAuthToken(recTransShipHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, recTransShipHeader."No.");
//         if recAuthData.Findlast() then begin

//             txtDecryptedSek := recAuthData.DecryptedSEK;

//             Message(jsonString);

//             GSTInv_DLL := GSTInv_DLL.RSA_AES();
//             // base64IRN := CU_Base64.ToBase64(JsonText);
//             encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

//             jsonObjectlinq := jsonObjectlinq.JObject();
//             jsonWriter2 := jsonObjectlinq.CreateWriter();

//             jsonWriter2.WritePropertyName('action');
//             jsonWriter2.WriteValue('CANEWB');

//             jsonWriter2.WritePropertyName('Data');
//             jsonWriter2.WriteValue(encryptedIRNPayload);

//             finalPayload := jsonObjectlinq.ToString();
//             // Message('FinalIRNPayload %1 ', finalPayload);
//             CU_TransferEInvoice.Call_IRN_API(recAuthData, finalPayload, false, recTransShipHeader, false, true);
//         end;

//     end;


//     procedure UpdateEWayCancelHeader(txtEwayNum: text; txtEWayCancelDt: Text; recTrShipHeader: Record "Transfer Shipment Header")
//     var
//         recTrShHeader: Record "Transfer Shipment Header";
//         CUSIEINvoice: Codeunit E_Invoice_SalesInvoice;
//         txtCancelDT: text;

//     begin
//         recTrShHeader.get(recTrShipHeader."No.");
//         recTrShHeader."E-Way Bill No." := txtEwayNum;
//         // txtCancelDT := CUSIEINvoice.ConvertAckDt(txtEWayCancelDt);
//         recTrShHeader."E-Way Bill Cancel Date" := txtEWayCancelDt;
//         recTrShHeader.Modify();
//     end;

//     procedure ParseResponse()
//     var
//     begin
//     end;
// }

