
// codeunit 50115 "e-Invoice Json Handler2"
// {
//     Permissions = tabledata "Sales Invoice Header" = rmi,
//                   tabledata "Sales Cr.Memo Header" = rmi;

//     trigger OnRun()
//     begin
//         // GenerateAuthToken();
//         //     Initialize();

//         /*if IsInvoice then
//             RunSalesInvoice()
//         else
//             RunSalesCrMemo();
//         JObject.WriteTo(JsonText);

//         if DocumentNo <> '' then
//             Message(JsonText)
//         else
//             Error(DocumentNoBlankErr);*/
//     end;


//     var

//         SalesInvoiceHeader: Record "Sales Invoice Header";
//         SalesCrMemoHeader: Record "Sales Cr.Memo Header";
//         JObject: JsonObject;
//         JsonArrayData: JsonArray;
//         pgSalesOrder: Page "Sales Order";
//         JsonText: Text;
//         DocumentNo: Text[20];
//         IsInvoice: Boolean;
//         eInvoiceNotApplicableCustErr: Label 'E-Invoicing is not applicable for Unregistered Customer.';
//         DocumentNoBlankErr: Label 'E-Invoicing is not supported if document number is blank in the current document.';
//         SalesLinesMaxCountLimitErr: Label 'E-Invoice allowes only 100 lines per Invoice. Current transaction is having %1 lines.', Comment = '%1 = Sales Lines count';
//         IRNTxt: Label 'Irn', Locked = true;
//         AcknowledgementNoTxt: Label 'AckNo', Locked = true;
//         AcknowledgementDateTxt: Label 'AckDt', Locked = true;
//         IRNHashErr: Label 'No matched IRN Hash %1 found to update.', Comment = '%1 = IRN Hash';
//         SignedQRCodeTxt: Label 'SignedQRCode', Locked = true;
//         CGSTLbl: Label 'CGST', Locked = true;
//         SGSTLbl: label 'SGST', Locked = true;
//         IGSTLbl: Label 'IGST', Locked = true;
//         CESSLbl: Label 'CESS', Locked = true;

//     [Scope('OnPrem')]
//     Procedure IntialiseAccesToken(): text
//     var
//         url: text[250];
//         headers: HttpHeaders;
//         JsonString: text;
//         //HttpWebRequestMgt:HttpRequestMessage;
//         client: httpclient;
//         response: HttpResponseMessage;
//         jobject: jsonobject;
//         GetAccessTokenNo: text;
//         responsetxt: text;
//         HttpWebRequestMgt: codeunit "Http Web Request Mgt.";
//         tempblob2: Codeunit "Temp Blob";
//         ReqBodyOutStream: OutStream;
//         ReqBodyInStream: InStream;
//         JsonAsText: text;
//         Instr: InStream;
//         apiresult: Integer;
//         tofile: text;
//         // HttpStatusCode: DotNet HttpStatusCode;
//         //ResponseHeaders: DotNet NameValueCollection;
//         recGSTRegNo: Record "GST Registration Nos.";

//     // HttpStatusCode: WebServiceActionResultCode;
//     // ResponseHeaders: HttpResponseMessage;
//     begin
//         url := 'https://ajf2m0r1na8eau2bn0brcou5h2i0-custuatdev.qwikcilver.com/QwikCilver/eGMS.RestAPI/api/v2/authorize ';


//         Clear(HttpWebRequestMgt);
//         HttpWebRequestMgt.Initialize(Url);
//         HttpWebRequestMgt.DisableUI;
//         HttpWebRequestMgt.SetMethod('POST');
//         HttpWebRequestMgt.AddHeader('client_id', 'AAKCS29TXP3G937');
//         HttpWebRequestMgt.AddHeader('client_secret', 'xDdRrf6L0Zzn42HhVvAP');
//         HttpWebRequestMgt.AddHeader('Content-Type', 'application/json; charset=utf-8');
//         HttpWebRequestMgt.AddHeader('GSTIN', 'AAKCS29TXP3G937');
//         HttpWebRequestMgt.AddBodyBlob(tempblob2);

//         TempBlob2.CREATEOUTSTREAM(ReqBodyOutStream, TEXTENCODING::UTF8);
//         ReqBodyOutStream.WRITETEXT('{"Data": "amMy4UXLuG5878PuVK/4KkJdbLIH7H4U7v+uLfZFMWoRr5jWO0015IB8eFNsc305q9ziWlxkCiqOAiHRgm3KJRY5xGngHe7HFjxuVgpEDzrB6Q7wp3NGmRZH8WnfoZMg1h3GXJ3x+NOR+QnymnAnyjAtgtOz19JZgnhF3uwI7UNiH2QpG1r1HkVHSvuBbZfNkRYcUqCL0pThyQD09LXYStYPqEVHKoPSydJdHFlwzAxjBFYMCzpAUszUlrcdTN1DHCU3d/ZyrjFfc+j63dZz3xZoGNO5MAfT5pEVs4Mj5ccztNVqPc/Aw6xie+Dx+V/8kJDiUBqWHgYMl70JLZkC2A=="}');
//         TempBlob2.CREATEINSTREAM(ReqBodyInStream);
//         HttpWebRequestMgt.AddBodyBlob(tempblob2);
//         DownloadFromStream(ReqBodyInStream, '', '', '', tofile);
//         tempblob2.CREATEINSTREAM(Instr);
//         /*
//                 IF HttpWebRequestMgt.GetResponse(Instr, HttpStatusCode, ResponseHeaders) THEN BEGIN
//                     ApiResult := Instr.ReadText(JsonAsText, 20000);
//                     IF HttpStatusCode.ToString = HttpStatusCode.OK.ToString THEN BEGIN
//                         ApiResult := Instr.ReadText(JsonAsText, 20000);
//                         jobject.ReadFrom(JsonAsText);

//                         Message(JsonAsText);
//                     END ELSE begin
//                         ApiResult := Instr.ReadText(JsonAsText, 20000);
//                         MESSAGE('status code not ok');
//                     End;
//                 END ELSE
//                     MESSAGE('no response from api');
//         */
//     end;


//     procedure GenerateIRN_01(RecSalesHeader: Record "Sales Invoice Header")
//     var
//         txtDecryptedSek: text;
//         GSTInv_DLL: DotNet GSTEncr_Decr;
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         jsonwriter1: DotNet JsonTextWriter;
//         jsonObjectlinq: DotNet JObject;
//         encryptedIRNPayload: text;
//         finalPayload: text;
//         SalesCrMemoHeader: Record "Sales Cr.Memo Header";
//     begin

//         IsInvoice := true;


//         if IsInvoice then
//             RunSalesInvoice(RecSalesHeader)
//         else
//             RunSalesCrMemo(SalesCrMemoHeader);
//         JObject.WriteTo(JsonText);
//         Message(JsonText);

//         GenerateAuthToken(RecSalesHeader);
//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, RecSalesHeader."No.");
//         if recAuthData.Findlast() then begin
//             txtDecryptedSek := recAuthData.DecryptedSEK;

//             GSTInv_DLL := GSTInv_DLL.RSA_AES();
//             encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);

//             jsonObjectlinq := jsonObjectlinq.JObject();
//             jsonwriter1 := jsonObjectlinq.CreateWriter();

//             jsonwriter1.WritePropertyName('Data');
//             jsonwriter1.WriteValue(encryptedIRNPayload);

//             finalPayload := jsonObjectlinq.ToString();
//             Call_IRN_API(recAuthData, finalPayload, RecSalesHeader);
//         end;
//         if DocumentNo <> '' then
//             Message(JsonText)
//         else
//             Error(DocumentNoBlankErr);

//     end;



//     procedure SetSalesInvHeader(SalesInvoiceHeaderBuff: Record "Sales Invoice Header")
//     begin
//         SalesInvoiceHeader := SalesInvoiceHeaderBuff;
//         IsInvoice := true;
//     end;

//     procedure SetCrMemoHeader(SalesCrMemoHeaderBuff: Record "Sales Cr.Memo Header")
//     begin
//         SalesCrMemoHeader := SalesCrMemoHeaderBuff;
//         IsInvoice := false;
//     end;

//     procedure GenerateCanceledInvoice()
//     begin
//         Initialize();

//         if IsInvoice then begin
//             DocumentNo := SalesInvoiceHeader."No.";
//             WriteCancellationJSON(
//               SalesInvoiceHeader."IRN Hash", SalesInvoiceHeader."Cancel Reason", Format(SalesInvoiceHeader."Cancel Reason"))
//         end else begin
//             DocumentNo := SalesCrMemoHeader."No.";
//             WriteCancellationJSON(
//               SalesCrMemoHeader."IRN Hash", SalesCrMemoHeader."Cancel Reason", Format(SalesCrMemoHeader."Cancel Reason"));
//         end;
//         if DocumentNo <> '' then
//             ExportAsJson(DocumentNo);
//     end;

//     procedure GetEInvoiceResponse(var RecRef: RecordRef)
//     var
//         JSONManagement: Codeunit "JSON Management";
//         //v  QRGenerator: Codeunit "QR Generator";
//         TempBlob: Codeunit "Temp Blob";
//         FieldRef: FieldRef;
//         JsonString: Text;
//         TempIRNTxt: Text;
//         TempDateTime: DateTime;
//         AcknowledgementDateTimeText: Text;
//         AcknowledgementDate: Date;
//         AcknowledgementTime: Time;
//     begin
//         JsonString := GetResponseText();
//         if (JsonString = '') or (JsonString = '[]') then
//             exit;

//         JSONManagement.InitializeObject(JsonString);
//         FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("IRN Hash"));
//         TempIRNTxt := FieldRef.Value;
//         if TempIRNTxt = JSONManagement.GetValue(IRNTxt) then begin
//             FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("Acknowledgement No."));
//             FieldRef.Value := JSONManagement.GetValue(AcknowledgementNoTxt);

//             AcknowledgementDateTimeText := JSONManagement.GetValue(AcknowledgementDateTxt);
//             Evaluate(AcknowledgementDate, CopyStr(AcknowledgementDateTimeText, 1, 10));
//             Evaluate(AcknowledgementTime, CopyStr(AcknowledgementDateTimeText, 11, 8));
//             TempDateTime := CreateDateTime(AcknowledgementDate, AcknowledgementTime);
//             FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("Acknowledgement Date"));

//             FieldRef.Value := TempDateTime;
//             FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo(IsJSONImported));
//             FieldRef.Value := true;
//             //   QRGenerator.GenerateQRCodeImage(JSONManagement.GetValue(SignedQRCodeTxt), TempBlob);
//             FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("QR Code"));
//             TempBlob.ToRecordRef(RecRef, SalesInvoiceHeader.FieldNo("QR Code"));
//             RecRef.Modify();
//         end else
//             Error(IRNHashErr, TempIRNTxt);
//     end;

//     local procedure GetResponseText() ResponseText: Text
//     var
//         TempBlob: Codeunit "Temp Blob";
//         InStream: InStream;
//         FileText: Text;
//     begin
//         TempBlob.CreateInStream(InStream);
//         UploadIntoStream('', '', '', FileText, InStream);

//         if FileText = '' then
//             exit;

//         InStream.ReadText(ResponseText);
//     end;


//     local procedure WriteCancelJsonFileHeader()
//     begin
//         JObject.Add('Version', '1.01');
//         JsonArrayData.Add(JObject);
//     end;

//     local procedure WriteCancellationJSON(
//         IRNHash: Text[64];
//         CancelReason: Enum "e-Invoice Cancel Reason";
//                           CancelRemark: Text[100])
//     var
//         CancelJsonObject: JsonObject;
//     begin
//         WriteCancelJsonFileHeader();
//         CancelJsonObject.Add('Canceldtls', '');
//         CancelJsonObject.Add('IRN', IRNHash);
//         CancelJsonObject.Add('CnlRsn', Format(CancelReason));
//         CancelJsonObject.Add('CnlRem', CancelRemark);

//         JsonArrayData.Add(CancelJsonObject);
//         JObject.Add('ExpDtls', JsonArrayData);
//     end;

//     local procedure RunSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
//     begin
//         if not IsInvoice then
//             exit;

//         if SalesInvoiceHeader."GST Customer Type" in [
//             SalesInvoiceHeader."GST Customer Type"::Unregistered,
//             SalesInvoiceHeader."GST Customer Type"::" "]
//         then
//             Error(eInvoiceNotApplicableCustErr);

//         DocumentNo := SalesInvoiceHeader."No.";
//         WriteJsonFileHeader();
//         ReadTransactionDetails(SalesInvoiceHeader."GST Customer Type", SalesInvoiceHeader."Ship-to Code");
//         ReadDocumentHeaderDetails(SalesInvoiceHeader);
//         ReadDocumentSellerDetails(SalesInvoiceHeader);
//         ReadDocumentBuyerDetails(SalesInvoiceHeader);
//         ReadDocumentShippingDetails(SalesInvoiceHeader);
//         ReadDocumentItemList(SalesInvoiceHeader);
//         ReadDocumentTotalDetails(SalesInvoiceHeader);
//         ReadExportDetails(SalesInvoiceHeader);
//     end;

//     local procedure RunSalesCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
//     begin
//         if IsInvoice then
//             exit;

//         if SalesCrMemoHeader."GST Customer Type" in [
//             SalesCrMemoHeader."GST Customer Type"::Unregistered,
//             SalesCrMemoHeader."GST Customer Type"::" "]
//         then
//             Error(eInvoiceNotApplicableCustErr);

//         DocumentNo := SalesCrMemoHeader."No.";
//         WriteJsonFileHeader();
//         ReadTransactionDetails(SalesCrMemoHeader."GST Customer Type", SalesCrMemoHeader."Ship-to Code");
//         // ReadDocumentHeaderDetails();
//         // ReadDocumentSellerDetails();
//         // ReadDocumentBuyerDetails();
//         // ReadDocumentShippingDetails();
//         // ReadDocumentItemList();
//         // ReadDocumentTotalDetails();
//         // ReadExportDetails();
//     end;

//     local procedure Initialize()
//     begin
//         Clear(JObject);
//         Clear(JsonArrayData);
//         Clear(JsonText);
//     end;

//     local procedure WriteJsonFileHeader()
//     begin
//         JObject.Add('TaxSch', 'GST');
//         // JObject.Add('Version', '1.03');//Wronggggggg
//         JObject.Add('Version', '1.1');
//         // JObject.Add('Irn', '');//Wrongggggg
//         JsonArrayData.Add(JObject);
//     end;

//     local procedure ReadTransactionDetails(GSTCustType: Enum "GST Customer Type"; ShipToCode: Code[12])
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice then
//             ReadInvoiceTransactionDetails(GSTCustType, ShipToCode)
//         else
//             ReadCreditMemoTransactionDetails(GSTCustType, ShipToCode);
//     end;

//     local procedure ReadCreditMemoTransactionDetails(GSTCustType: Enum "GST Customer Type"; ShipToCode: Code[12])
//     var
//         SalesCrMemoLine: Record "Sales Cr.Memo Line";
//         NatureOfSupply: Text[3];
//         SupplyType: Text[3];
//     begin
//         if IsInvoice then
//             exit;

//         if GSTCustType in [
//             SalesCrMemoHeader."GST Customer Type"::Registered,
//             SalesCrMemoHeader."GST Customer Type"::Exempted]
//         then
//             NatureOfSupply := 'B2B'
//         else
//             NatureOfSupply := 'EXP';

//         if ShipToCode <> '' then begin
//             SalesCrMemoLine.SetRange("Document No.", DocumentNo);
//             if SalesCrMemoLine.FindSet() then
//                 repeat
//                     if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" then
//                         SupplyType := 'REG'
//                     else
//                         SupplyType := 'SHP';
//                 until SalesCrMemoLine.Next() = 0;
//         end else
//             SupplyType := 'REG';

//         WriteTransactionDetails(NatureOfSupply, 'RG', SupplyType, 'false', 'Y', '');
//     end;

//     local procedure ReadInvoiceTransactionDetails(GSTCustType: Enum "GST Customer Type"; ShipToCode: Code[12])
//     var
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         NatureOfSupplyCategory: Text[3];
//         SupplyType: Text[3];
//     begin
//         if not IsInvoice then
//             exit;

//         if GSTCustType in [
//             SalesInvoiceHeader."GST Customer Type"::Registered,
//             SalesInvoiceHeader."GST Customer Type"::Exempted]
//         then
//             NatureOfSupplyCategory := 'B2B'
//         else
//             // NatureOfSupplyCategory := 'EXP';//Wrongggggg
//             NatureOfSupplyCategory := 'EXPWP';//CITS_RS

//         if ShipToCode <> '' then begin
//             SalesInvoiceLine.SetRange("Document No.", DocumentNo);
//             if SalesInvoiceLine.FindSet() then
//                 repeat
//                     if SalesInvoiceLine."GST Place of Supply" <> SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" then
//                         SupplyType := 'SHP'
//                     else
//                         SupplyType := 'REG';
//                 until SalesInvoiceLine.Next() = 0;
//         end else
//             SupplyType := 'REG';

//         WriteTransactionDetails(NatureOfSupplyCategory, 'RG', SupplyType, 'false', 'Y', '');
//     end;

//     local procedure WriteTransactionDetails(
//         SupplyCategory: Text[3];
//         RegRev: Text[2];
//         SupplyType: Text[3];
//         EcmTrnSel: Text[5];
//         EcmTrn: Text[1];
//         EcmGstin: Text[15])
//     var
//         JTranDetails: JsonObject;
//     begin
//         JTranDetails.Add('Catg', SupplyCategory);
//         JTranDetails.Add('RegRev', RegRev);
//         JTranDetails.Add('Typ', SupplyType);
//         JTranDetails.Add('EcmTrnSel', EcmTrnSel);
//         JTranDetails.Add('EcmTrn', EcmTrn);
//         JTranDetails.Add('EcmGstin', EcmGstin);

//         JsonArrayData.Add(JTranDetails);
//         JObject.Add('TranDtls', JsonArrayData);
//     end;

//     local procedure ReadDocumentHeaderDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         InvoiceType: Text[3];
//         PostingDate: Text[10];
//         OriginalInvoiceNo: Text[16];
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice then begin
//             if (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::"Debit Note") or
//                (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::Supplementary)
//             then
//                 InvoiceType := 'DBN'
//             else
//                 InvoiceType := 'INV';
//             PostingDate := Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>');
//         end else begin
//             InvoiceType := 'CRN';
//             PostingDate := Format(SalesCrMemoHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>');
//         end;

//         OriginalInvoiceNo := CopyStr(GetReferenceInvoiceNo(DocumentNo), 1, 16);
//         WriteDocumentHeaderDetails(InvoiceType, CopyStr(DocumentNo, 1, 16), PostingDate, OriginalInvoiceNo);
//     end;

//     local procedure WriteDocumentHeaderDetails(InvoiceType: Text[3]; DocumentNo: Text[16]; PostingDate: Text[10]; OriginalInvoiceNo: Text[16])
//     var
//         JDocumentHeaderDetails: JsonObject;
//     begin
//         JDocumentHeaderDetails.Add('Typ', InvoiceType);
//         JDocumentHeaderDetails.Add('No', DocumentNo);
//         JDocumentHeaderDetails.Add('Dt', PostingDate);
//         JDocumentHeaderDetails.Add('OrgInvNo', OriginalInvoiceNo);

//         JsonArrayData.Add(JDocumentHeaderDetails);
//         JObject.Add('DocDtls', JsonArrayData);
//     end;

//     local procedure ReadExportDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice then
//             ReadInvoiceExportDetails(SalesInvoiceHeader)
//         else
//             ReadCrMemoExportDetails();
//     end;

//     local procedure ReadCrMemoExportDetails()
//     var
//         SalesCrMemoLine: Record "Sales Cr.Memo Line";
//         ExportCategory: Text[3];
//         WithPayOfDuty: Text[1];
//         ShipmentBillNo: Text[16];
//         ShipmentBillDate: Text[10];
//         ExitPort: Text[10];
//         DocumentAmount: Decimal;
//         CurrencyCode: Text[3];
//         CountryCode: Text[2];
//     begin
//         if IsInvoice then
//             exit;

//         if not (SalesCrMemoHeader."GST Customer Type" in [
//             SalesCrMemoHeader."GST Customer Type"::Export,
//             SalesCrMemoHeader."GST Customer Type"::"Deemed Export",
//             SalesCrMemoHeader."GST Customer Type"::"SEZ Unit",
//             SalesCrMemoHeader."GST Customer Type"::"SEZ Development"])
//         then
//             exit;

//         case SalesCrMemoHeader."GST Customer Type" of
//             SalesCrMemoHeader."GST Customer Type"::Export:
//                 ExportCategory := 'DIR';
//             SalesCrMemoHeader."GST Customer Type"::"Deemed Export":
//                 ExportCategory := 'DEM';
//             SalesCrMemoHeader."GST Customer Type"::"SEZ Unit":
//                 ExportCategory := 'SEZ';
//             "GST Customer Type"::"SEZ Development":
//                 ExportCategory := 'SED';
//         end;

//         if SalesCrMemoHeader."GST Without Payment of Duty" then
//             WithPayOfDuty := 'N'
//         else
//             WithPayOfDuty := 'Y';

//         ShipmentBillNo := CopyStr(SalesCrMemoHeader."Bill Of Export No.", 1, 16);
//         ShipmentBillDate := Format(SalesCrMemoHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
//         ExitPort := SalesCrMemoHeader."Exit Point";

//         SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
//         if SalesCrMemoLine.FindSet() then
//             repeat
//                 DocumentAmount := DocumentAmount + SalesCrMemoLine.Amount;
//             until SalesCrMemoLine.Next() = 0;

//         CurrencyCode := CopyStr(SalesCrMemoHeader."Currency Code", 1, 3);
//         CountryCode := CopyStr(SalesCrMemoHeader."Bill-to Country/Region Code", 1, 2);

//         WriteExportDetails(ExportCategory, WithPayOfDuty, ShipmentBillNo, ShipmentBillDate, ExitPort, DocumentAmount, CurrencyCode, CountryCode);
//     end;

//     local procedure ReadInvoiceExportDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         ExportCategory: Text[3];
//         WithPayOfDuty: Text[1];
//         ShipmentBillNo: Text[16];
//         ShipmentBillDate: Text[10];
//         ExitPort: Text[10];
//         DocumentAmount: Decimal;
//         CurrencyCode: Text[3];
//         CountryCode: Text[2];
//     begin
//         if not IsInvoice then
//             exit;

//         if not (SalesInvoiceHeader."GST Customer Type" in [
//             SalesInvoiceHeader."GST Customer Type"::Export,
//             SalesInvoiceHeader."GST Customer Type"::"Deemed Export",
//             SalesInvoiceHeader."GST Customer Type"::"SEZ Unit",
//             SalesInvoiceHeader."GST Customer Type"::"SEZ Development"])
//         then
//             exit;

//         case SalesInvoiceHeader."GST Customer Type" of
//             SalesInvoiceHeader."GST Customer Type"::Export:
//                 ExportCategory := 'DIR';
//             SalesInvoiceHeader."GST Customer Type"::"Deemed Export":
//                 ExportCategory := 'DEM';
//             SalesInvoiceHeader."GST Customer Type"::"SEZ Unit":
//                 ExportCategory := 'SEZ';
//             SalesInvoiceHeader."GST Customer Type"::"SEZ Development":
//                 ExportCategory := 'SED';
//         end;

//         if SalesInvoiceHeader."GST Without Payment of Duty" then
//             WithPayOfDuty := 'N'
//         else
//             WithPayOfDuty := 'Y';

//         ShipmentBillNo := CopyStr(SalesInvoiceHeader."Bill Of Export No.", 1, 16);
//         ShipmentBillDate := Format(SalesInvoiceHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
//         ExitPort := SalesInvoiceHeader."Exit Point";

//         SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
//         if SalesInvoiceLine.FindSet() then
//             repeat
//                 DocumentAmount := DocumentAmount + SalesInvoiceLine.Amount;
//             until SalesInvoiceLine.Next() = 0;

//         CurrencyCode := CopyStr(SalesInvoiceHeader."Currency Code", 1, 3);
//         CountryCode := CopyStr(SalesInvoiceHeader."Bill-to Country/Region Code", 1, 2);

//         WriteExportDetails(ExportCategory, WithPayOfDuty, ShipmentBillNo, ShipmentBillDate, ExitPort, DocumentAmount, CurrencyCode, CountryCode);
//     end;

//     local procedure WriteExportDetails(
//         ExportCategory: Text[3];
//         WithPayOfDuty: Text[1];
//         ShipmentBillNo: Text[16];
//         ShipmentBillDate: Text[10];
//         ExitPort: Text[10];
//         DocumentAmount: Decimal;
//         CurrencyCode: Text[3];
//         CountryCode: Text[2])
//     var
//         JExpDetails: JsonObject;
//     begin
//         JExpDetails.Add('ExpCat', ExportCategory);
//         JExpDetails.Add('WithPay', WithPayOfDuty);
//         JExpDetails.Add('ShipBNo', ShipmentBillNo);
//         JExpDetails.Add('ShipBDt', ShipmentBillDate);
//         JExpDetails.Add('Port', ExitPort);
//         JExpDetails.Add('InvForCur', DocumentAmount);
//         JExpDetails.Add('ForCur', CurrencyCode);
//         JExpDetails.Add('CntCode', CountryCode);

//         JsonArrayData.Add(JExpDetails);
//         JObject.Add('ExpDtls', JsonArrayData);
//     end;

//     local procedure ReadDocumentSellerDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         CompanyInformationBuff: Record "Company Information";
//         LocationBuff: Record "Location";
//         StateBuff: Record "State";
//         GSTRegistrationNo: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Flno: Text[60];
//         Loc: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         Email: Text[50];
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice then begin
//             GSTRegistrationNo := SalesInvoiceHeader."Location GST Reg. No.";
//             LocationBuff.Get(SalesInvoiceHeader."Location Code");
//         end else begin
//             GSTRegistrationNo := SalesCrMemoHeader."Location GST Reg. No.";
//             LocationBuff.Get(SalesCrMemoHeader."Location Code");
//         end;

//         CompanyInformationBuff.Get();
//         CompanyName := CompanyInformationBuff.Name;
//         Address := LocationBuff.Address;
//         Address2 := LocationBuff."Address 2";
//         Flno := '';
//         Loc := '';
//         City := LocationBuff.City;
//         PostCode := CopyStr(LocationBuff."Post Code", 1, 6);
//         StateBuff.Get(LocationBuff."State Code");
//         StateCode := StateBuff."State Code (GST Reg. No.)";
//         PhoneNumber := CopyStr(LocationBuff."Phone No.", 1, 10);
//         Email := CopyStr(LocationBuff."E-Mail", 1, 50);

//         WriteSellerDetails(GSTRegistrationNo, CompanyName, Address, Address2, Flno, Loc, City, PostCode, StateCode, PhoneNumber, Email);
//     end;

//     local procedure WriteSellerDetails(
//         GSTRegistrationNo: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Flno: Text[60];
//         Loc: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         Email: Text[50])
//     var
//         JSellerDetails: JsonObject;
//     begin
//         JSellerDetails.Add('Gstin', GSTRegistrationNo);
//         JSellerDetails.Add('TrdNm', CompanyName);
//         JSellerDetails.Add('Bno', Address);
//         JSellerDetails.Add('Bnm', Address2);
//         JSellerDetails.Add('Flno', Flno);
//         JSellerDetails.Add('Loc', Loc);
//         JSellerDetails.Add('Dst', City);
//         JSellerDetails.Add('Pin', PostCode);
//         JSellerDetails.Add('Stcd', StateCode);
//         JSellerDetails.Add('Ph', PhoneNumber);
//         JSellerDetails.Add('Em', Email);

//         JsonArrayData.Add(JSellerDetails);
//         JObject.Add('SellerDtls', JsonArrayData);
//     end;

//     local procedure ReadDocumentBuyerDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice then
//             ReadInvoiceBuyerDetails(SalesInvoiceHeader)
//         else
//             ReadCrMemoBuyerDetails();
//     end;

//     local procedure ReadInvoiceBuyerDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         Contact: Record Contact;
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         ShiptoAddress: Record "Ship-to Address";
//         StateBuff: Record State;
//         GSTRegistrationNumber: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Floor: Text[60];
//         AddressLocation: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         Email: Text[50];
//     begin
//         GSTRegistrationNumber := SalesInvoiceHeader."Customer GST Reg. No.";
//         CompanyName := SalesInvoiceHeader."Bill-to Name";
//         Address := SalesInvoiceHeader."Bill-to Address";
//         Address2 := SalesInvoiceHeader."Bill-to Address 2";
//         Floor := '';
//         AddressLocation := '';
//         City := SalesInvoiceHeader."Bill-to City";
//         PostCode := CopyStr(SalesInvoiceHeader."Bill-to Post Code", 1, 6);

//         SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
//         if SalesInvoiceLine.FindFirst() then
//             case SalesInvoiceLine."GST Place of Supply" of
//                 SalesInvoiceLine."GST Place of Supply"::"Bill-to Address":
//                     begin
//                         if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
//                             StateBuff.Get(SalesInvoiceHeader."GST Bill-to State Code");
//                             StateCode := StateBuff."State Code for eTDS/TCS";
//                         end else
//                             StateCode := '';

//                         if Contact.Get(SalesInvoiceHeader."Bill-to Contact No.") then begin
//                             PhoneNumber := CopyStr(Contact."Phone No.", 1, 10);
//                             Email := CopyStr(Contact."E-Mail", 1, 50);
//                         end else begin
//                             PhoneNumber := '';
//                             Email := '';
//                         end;
//                     end;

//                 SalesInvoiceLine."GST Place of Supply"::"Ship-to Address":
//                     begin
//                         if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
//                             StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
//                             StateCode := StateBuff."State Code for eTDS/TCS";
//                         end else
//                             StateCode := '';

//                         if ShiptoAddress.Get(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code") then begin
//                             PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
//                             Email := CopyStr(ShiptoAddress."E-Mail", 1, 50);
//                         end else begin
//                             PhoneNumber := '';
//                             Email := '';
//                         end;
//                     end;
//                 else begin
//                         StateCode := '';
//                         PhoneNumber := '';
//                         Email := '';
//                     end;
//             end;
//         WriteBuyerDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, Email);
//     end;

//     local procedure ReadCrMemoBuyerDetails()
//     var
//         Contact: Record Contact;
//         SalesCrMemoLine: Record "Sales Cr.Memo Line";
//         ShiptoAddress: Record "Ship-to Address";
//         StateBuff: Record State;
//         GSTRegistrationNumber: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Floor: Text[60];
//         AddressLocation: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         Email: Text[50];
//     begin
//         GSTRegistrationNumber := SalesCrMemoHeader."Customer GST Reg. No.";
//         CompanyName := SalesCrMemoHeader."Bill-to Name";
//         Address := SalesCrMemoHeader."Bill-to Address";
//         Address2 := SalesCrMemoHeader."Bill-to Address 2";
//         Floor := '';
//         AddressLocation := '';
//         City := SalesCrMemoHeader."Bill-to City";
//         PostCode := CopyStr(SalesCrMemoHeader."Bill-to Post Code", 1, 6);
//         StateCode := '';
//         PhoneNumber := '';
//         Email := '';

//         SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
//         if SalesCrMemoLine.FindFirst() then
//             case SalesCrMemoLine."GST Place of Supply" of

//                 SalesCrMemoLine."GST Place of Supply"::"Bill-to Address":
//                     begin
//                         if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
//                             StateBuff.Get(SalesCrMemoHeader."GST Bill-to State Code");
//                             StateCode := StateBuff."State Code for eTDS/TCS";
//                         end;

//                         if Contact.Get(SalesCrMemoHeader."Bill-to Contact No.") then begin
//                             PhoneNumber := CopyStr(Contact."Phone No.", 1, 10);
//                             Email := CopyStr(Contact."E-Mail", 1, 50);
//                         end;
//                     end;

//                 SalesCrMemoLine."GST Place of Supply"::"Ship-to Address":
//                     begin
//                         if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
//                             StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
//                             StateCode := StateBuff."State Code for eTDS/TCS";
//                         end;

//                         if ShiptoAddress.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code") then begin
//                             PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
//                             Email := CopyStr(ShiptoAddress."E-Mail", 1, 50);
//                         end;
//                     end;
//             end;

//         WriteBuyerDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, Email);
//     end;

//     local procedure WriteBuyerDetails(
//         GSTRegistrationNumber: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Floor: Text[60];
//         AddressLocation: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         EmailID: Text[50])
//     var
//         JBuyerDetails: JsonObject;
//     begin
//         JBuyerDetails.Add('Gstin', GSTRegistrationNumber);
//         JBuyerDetails.Add('TrdNm', CompanyName);
//         JBuyerDetails.Add('Bno', Address);
//         JBuyerDetails.Add('Bnm', Address2);
//         JBuyerDetails.Add('Flno', Floor);
//         JBuyerDetails.Add('Loc', AddressLocation);
//         JBuyerDetails.Add('Dst', City);
//         JBuyerDetails.Add('Pin', PostCode);
//         JBuyerDetails.Add('Stcd', StateCode);
//         JBuyerDetails.Add('Ph', PhoneNumber);
//         JBuyerDetails.Add('Em', EmailID);

//         JsonArrayData.Add(JBuyerDetails);
//         JObject.Add('BuyerDtls', JsonArrayData);
//     end;

//     local procedure ReadDocumentShippingDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         ShiptoAddress: Record "Ship-to Address";
//         StateBuff: Record State;
//         GSTRegistrationNumber: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Floor: Text[60];
//         AddressLocation: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         EmailID: Text[50];
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice and (SalesInvoiceHeader."Ship-to Code" <> '') then begin
//             ShiptoAddress.Get(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code");
//             StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
//             CompanyName := SalesInvoiceHeader."Ship-to Name";
//             Address := SalesInvoiceHeader."Ship-to Address";
//             Address2 := SalesInvoiceHeader."Ship-to Address 2";
//             City := SalesInvoiceHeader."Ship-to City";
//             PostCode := CopyStr(SalesInvoiceHeader."Ship-to Post Code", 1, 6);
//         end else
//             if SalesCrMemoHeader."Ship-to Code" <> '' then begin
//                 ShiptoAddress.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code");
//                 StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
//                 CompanyName := SalesCrMemoHeader."Ship-to Name";
//                 Address := SalesCrMemoHeader."Ship-to Address";
//                 Address2 := SalesCrMemoHeader."Ship-to Address 2";
//                 City := SalesCrMemoHeader."Ship-to City";
//                 PostCode := CopyStr(SalesCrMemoHeader."Ship-to Post Code", 1, 6);
//             end;

//         GSTRegistrationNumber := ShiptoAddress."GST Registration No.";
//         Floor := '';
//         AddressLocation := '';
//         StateCode := StateBuff."State Code for eTDS/TCS";
//         PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
//         EmailID := CopyStr(ShiptoAddress."E-Mail", 1, 50);
//         WriteShippingDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, EmailID);
//     end;

//     local procedure WriteShippingDetails(
//         GSTRegistrationNumber: Text[20];
//         CompanyName: Text[100];
//         Address: Text[100];
//         Address2: Text[100];
//         Floor: Text[60];
//         AddressLocation: Text[60];
//         City: Text[60];
//         PostCode: Text[6];
//         StateCode: Text[10];
//         PhoneNumber: Text[10];
//         EmailID: Text[50])
//     var
//         JShippingDetails: JsonObject;
//     begin
//         JShippingDetails.Add('Gstin', GSTRegistrationNumber);
//         JShippingDetails.Add('TrdNm', CompanyName);
//         JShippingDetails.Add('Bno', Address);
//         JShippingDetails.Add('Bnm', Address2);
//         JShippingDetails.Add('Flno', Floor);
//         JShippingDetails.Add('Loc', AddressLocation);
//         JShippingDetails.Add('Dst', City);
//         JShippingDetails.Add('Pin', PostCode);
//         JShippingDetails.Add('Stcd', StateCode);
//         JShippingDetails.Add('Ph', PhoneNumber);
//         JShippingDetails.Add('Em', EmailID);

//         JsonArrayData.Add(JShippingDetails);
//         JObject.Add('ShipDtls', JsonArrayData);
//     end;

//     local procedure ReadDocumentTotalDetails(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         AssessableAmount: Decimal;
//         CGSTAmount: Decimal;
//         SGSTAmount: Decimal;
//         IGSTAmount: Decimal;
//         CessAmount: Decimal;
//         StateCessAmount: Decimal;
//         CESSNonAvailmentAmount: Decimal;
//         DiscountAmount: Decimal;
//         OtherCharges: Decimal;
//         TotalInvoiceValue: Decimal;
//     begin
//         Clear(JsonArrayData);
//         GetGSTValue(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue);
//         WriteDocumentTotalDetails(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue);
//     end;

//     local procedure WriteDocumentTotalDetails(
//         AssessableAmount: Decimal;
//         CGSTAmount: Decimal;
//         SGSTAmount: Decimal;
//         IGSTAmount: Decimal;
//         CessAmount: Decimal;
//         StateCessAmount: Decimal;
//         CessNonAdvanceVal: Decimal;
//         DiscountAmount: Decimal;
//         OtherCharges: Decimal;
//         TotalInvoiceAmount: Decimal)
//     var
//         JDocTotalDetails: JsonObject;
//     begin
//         JDocTotalDetails.Add('Assval', AssessableAmount);
//         JDocTotalDetails.Add('CgstVal', CGSTAmount);
//         JDocTotalDetails.Add('SgstVAl', SGSTAmount);
//         JDocTotalDetails.Add('IgstVal', IGSTAmount);
//         JDocTotalDetails.Add('CesVal', CessAmount);
//         JDocTotalDetails.Add('StCesVal', StateCessAmount);
//         JDocTotalDetails.Add('CesNonAdVal', CessNonAdvanceVal);
//         JDocTotalDetails.Add('Disc', DiscountAmount);
//         JDocTotalDetails.Add('OthChrg', OtherCharges);
//         JDocTotalDetails.Add('TotInvVal', TotalInvoiceAmount);

//         JsonArrayData.Add(JDocTotalDetails);
//         JObject.Add('ValDtls', JsonArrayData);
//     end;

//     local procedure ReadDocumentItemList(SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         SalesCrMemoLine: Record "Sales Cr.Memo Line";
//         AssessableAmount: Decimal;
//         CGSTRate: Decimal;
//         SGSTRate: Decimal;
//         IGSTRate: Decimal;
//         CessRate: Decimal;
//         CesNonAdval: Decimal;
//         StateCess: Decimal;
//         FreeQuantity: Decimal;
//         CGSTValue: Decimal;
//         SGSTValue: Decimal;
//         IGSTValue: Decimal;
//     begin
//         Clear(JsonArrayData);
//         if IsInvoice then begin
//             SalesInvoiceLine.SetRange("Document No.", DocumentNo);
//             if SalesInvoiceLine.FindSet() then begin
//                 if SalesInvoiceLine.Count > 100 then
//                     Error(SalesLinesMaxCountLimitErr, SalesInvoiceLine.Count);
//                 repeat
//                     if SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 then
//                         AssessableAmount := SalesInvoiceLine."GST Assessable Value (LCY)"
//                     else
//                         AssessableAmount := SalesInvoiceLine.Amount;

//                     FreeQuantity := 0;
//                     GetGSTComponentRate(
//                         SalesInvoiceLine."Document No.",
//                         SalesInvoiceLine."Line No.",
//                         CGSTRate,
//                         SGSTRate,
//                         IGSTRate,
//                         CessRate,
//                         CesNonAdval,
//                         StateCess);

//                     GetGSTValueForLine(SalesInvoiceLine."Line No.", CGSTValue, SGSTValue, IGSTValue);
//                     WriteItem(
//                       SalesInvoiceLine.Description + SalesInvoiceLine."Description 2", '',
//                       SalesInvoiceLine."HSN/SAC Code", '',
//                       SalesInvoiceLine.Quantity, FreeQuantity,
//                       CopyStr(SalesInvoiceLine."Unit of Measure Code", 1, 3),
//                       SalesInvoiceLine."Unit Price",
//                       SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
//                       SalesInvoiceLine."Line Discount Amount", 0,
//                       AssessableAmount, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess,
//                       AssessableAmount + CGSTValue + SGSTValue + IGSTValue);
//                 until SalesInvoiceLine.Next() = 0;
//             end;

//             JObject.Add('ItemList', JsonArrayData);
//         end else begin
//             SalesCrMemoLine.SetRange("Document No.", DocumentNo);
//             if SalesCrMemoLine.FindSet() then begin
//                 if SalesCrMemoLine.Count > 100 then
//                     Error(SalesLinesMaxCountLimitErr, SalesCrMemoLine.Count);

//                 repeat
//                     if SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 then
//                         AssessableAmount := SalesCrMemoLine."GST Assessable Value (LCY)"
//                     else
//                         AssessableAmount := SalesCrMemoLine.Amount;

//                     FreeQuantity := 0;
//                     GetGSTComponentRate(
//                         SalesCrMemoLine."Document No.",
//                         SalesCrMemoLine."Line No.",
//                         CGSTRate,
//                         SGSTRate,
//                         IGSTRate,
//                         CessRate,
//                         CesNonAdval,
//                         StateCess);

//                     GetGSTValueForLine(SalesCrMemoLine."Line No.", CGSTValue, SGSTValue, IGSTValue);
//                     WriteItem(
//                       SalesCrMemoLine.Description + SalesCrMemoLine."Description 2", '',
//                       SalesCrMemoLine."HSN/SAC Code", '',
//                       SalesCrMemoLine.Quantity, FreeQuantity,
//                       CopyStr(SalesCrMemoLine."Unit of Measure Code", 1, 3),
//                       SalesCrMemoLine."Unit Price",
//                       SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount",
//                       SalesCrMemoLine."Line Discount Amount", 0,
//                       AssessableAmount, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess,
//                       AssessableAmount + CGSTValue + SGSTValue + IGSTValue);
//                 until SalesCrMemoLine.Next() = 0;
//             end;

//             JObject.Add('ItemList', JsonArrayData);
//         end;
//     end;

//     local procedure WriteItem(
//         ProductName: Text;
//         ProductDescription: Text;
//         HSNCode: Text[10];
//         BarCode: Text[30];
//         Quantity: Decimal;
//         FreeQuantity: Decimal;
//         Unit: Text[3];
//         UnitPrice: Decimal;
//         TotAmount: Decimal;
//         Discount: Decimal;
//         OtherCharges: Decimal;
//         AssessableAmount: Decimal;
//         CGSTRate: Decimal;
//         SGSTRate: Decimal;
//         IGSTRate: Decimal;
//         CESSRate: Decimal;
//         CessNonAdvanceAmount: Decimal;
//         StateCess: Decimal;
//         TotalItemValue: Decimal)
//     var
//         JItem: JsonObject;
//     begin
//         JItem.Add('PrdNm', ProductName);
//         JItem.Add('PrdDesc', ProductDescription);
//         JItem.Add('HsnCd', HSNCode);
//         JItem.Add('Barcde', BarCode);
//         JItem.Add('Qty', Quantity);
//         JItem.Add('FreeQty', FreeQuantity);
//         JItem.Add('Unit', Unit);
//         JItem.Add('UnitPrice', UnitPrice);
//         JItem.Add('TotAmt', TotAmount);
//         JItem.Add('Discount', Discount);
//         JItem.Add('OthChrg', OtherCharges);
//         JItem.Add('AssAmt', AssessableAmount);
//         JItem.Add('CgstRt', CGSTRate);
//         JItem.Add('SgstRt', SGSTRate);
//         JItem.Add('IgstRt', IGSTRate);
//         JItem.Add('CesRt', CESSRate);
//         JItem.Add('CesNonAdval', CessNonAdvanceAmount);
//         JItem.Add('StateCes', StateCess);
//         JItem.Add('TotItemVal', TotalItemValue);

//         JsonArrayData.Add(JItem);
//     end;

//     local procedure ExportAsJson(FileName: Text[20])
//     var
//         TempBlob: Codeunit "Temp Blob";
//         ToFile: Variant;
//         InStream: InStream;
//         OutStream: OutStream;
//     begin
//         JObject.WriteTo(JsonText);
//         TempBlob.CreateOutStream(OutStream);
//         OutStream.WriteText(JsonText);
//         ToFile := FileName + '.json';
//         TempBlob.CreateInStream(InStream);
//         DownloadFromStream(InStream, 'e-Invoice', '', '', ToFile);
//     end;

//     local procedure GetReferenceInvoiceNo(DocNo: Code[20]) RefInvNo: Code[20]
//     var
//         ReferenceInvoiceNo: Record "Reference Invoice No.";
//     begin
//         ReferenceInvoiceNo.SetRange("Document No.", DocNo);
//         if ReferenceInvoiceNo.FindFirst() then
//             RefInvNo := ReferenceInvoiceNo."Reference Invoice Nos."
//         else
//             RefInvNo := '';
//     end;

//     local procedure GetGSTComponentRate(
//         DocumentNo: Code[20];
//         LineNo: Integer;
//         var CGSTRate: Decimal;
//         var SGSTRate: Decimal;
//         var IGSTRate: Decimal;
//         var CessRate: Decimal;
//         var CessNonAdvanceAmount: Decimal;
//         var StateCess: Decimal)
//     var
//         DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
//     begin
//         DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
//         DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);

//         DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
//         if DetailedGSTLedgerEntry.FindFirst() then
//             CGSTRate := DetailedGSTLedgerEntry."GST %"
//         else
//             CGSTRate := 0;

//         DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
//         if DetailedGSTLedgerEntry.FindFirst() then
//             SGSTRate := DetailedGSTLedgerEntry."GST %"
//         else
//             SGSTRate := 0;

//         DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
//         if DetailedGSTLedgerEntry.FindFirst() then
//             IGSTRate := DetailedGSTLedgerEntry."GST %"
//         else
//             IGSTRate := 0;

//         CessRate := 0;
//         CessNonAdvanceAmount := 0;
//         DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
//         if DetailedGSTLedgerEntry.FindFirst() then
//             if DetailedGSTLedgerEntry."GST %" > 0 then
//                 CessRate := DetailedGSTLedgerEntry."GST %"
//             else
//                 CessNonAdvanceAmount := Abs(DetailedGSTLedgerEntry."GST Amount");

//         StateCess := 0;
//         DetailedGSTLedgerEntry.SetRange("GST Component Code");
//         if DetailedGSTLedgerEntry.FindSet() then
//             repeat
//                 if not (DetailedGSTLedgerEntry."GST Component Code" in [CGSTLbl, SGSTLbl, IGSTLbl, CESSLbl])
//                 then
//                     StateCess := DetailedGSTLedgerEntry."GST %";
//             until DetailedGSTLedgerEntry.Next() = 0;
//     end;

//     local procedure GetGSTValue(
//         var AssessableAmount: Decimal;
//         var CGSTAmount: Decimal;
//         var SGSTAmount: Decimal;
//         var IGSTAmount: Decimal;
//         var CessAmount: Decimal;
//         var StateCessValue: Decimal;
//         var CessNonAdvanceAmount: Decimal;
//         var DiscountAmount: Decimal;
//         var OtherCharges: Decimal;
//         var TotalInvoiceValue: Decimal)
//     var
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         SalesCrMemoLine: Record "Sales Cr.Memo Line";
//         GSTLedgerEntry: Record "GST Ledger Entry";
//         DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
//         CurrencyExchangeRate: Record "Currency Exchange Rate";
//         CustLedgerEntry: Record "Cust. Ledger Entry";
//         TotGSTAmt: Decimal;
//     begin
//         GSTLedgerEntry.SetRange("Document No.", DocumentNo);

//         GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
//         if GSTLedgerEntry.FindSet() then
//             repeat
//                 CGSTAmount += Abs(GSTLedgerEntry."GST Amount");
//             until GSTLedgerEntry.Next() = 0
//         else
//             CGSTAmount := 0;

//         GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
//         if GSTLedgerEntry.FindSet() then
//             repeat
//                 SGSTAmount += Abs(GSTLedgerEntry."GST Amount")
//             until GSTLedgerEntry.Next() = 0
//         else
//             SGSTAmount := 0;

//         GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
//         if GSTLedgerEntry.FindSet() then
//             repeat
//                 IGSTAmount += Abs(GSTLedgerEntry."GST Amount")
//             until GSTLedgerEntry.Next() = 0
//         else
//             IGSTAmount := 0;

//         CessAmount := 0;
//         CessNonAdvanceAmount := 0;

//         DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
//         DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
//         if DetailedGSTLedgerEntry.FindFirst() then
//             repeat
//                 if DetailedGSTLedgerEntry."GST %" > 0 then
//                     CessAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
//                 else
//                     CessNonAdvanceAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
//             until GSTLedgerEntry.Next() = 0;

//         GSTLedgerEntry.SetFilter("GST Component Code", '<>CGST|<>SGST|<>IGST|<>CESS');
//         if GSTLedgerEntry.FindSet() then
//             repeat
//                 StateCessValue += Abs(GSTLedgerEntry."GST Amount");
//             until GSTLedgerEntry.Next() = 0;

//         if IsInvoice then begin
//             SalesInvoiceLine.SetRange("Document No.", DocumentNo);
//             if SalesInvoiceLine.FindSet() then
//                 repeat
//                     AssessableAmount += SalesInvoiceLine.Amount;
//                     DiscountAmount += SalesInvoiceLine."Inv. Discount Amount";
//                 until SalesInvoiceLine.Next() = 0;
//             TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;

//             AssessableAmount := Round(
//                 CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//                   WorkDate(), SalesInvoiceHeader."Currency Code", AssessableAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
//             TotGSTAmt := Round(
//                 CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//                   WorkDate(), SalesInvoiceHeader."Currency Code", TotGSTAmt, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
//             DiscountAmount := Round(
//                 CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//                   WorkDate(), SalesInvoiceHeader."Currency Code", DiscountAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
//         end else begin
//             SalesCrMemoLine.SetRange("Document No.", DocumentNo);
//             if SalesCrMemoLine.FindSet() then begin
//                 repeat
//                     AssessableAmount += SalesCrMemoLine.Amount;
//                     DiscountAmount += SalesCrMemoLine."Inv. Discount Amount";
//                 until SalesCrMemoLine.Next() = 0;
//                 TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;
//             end;

//             AssessableAmount := Round(
//                 CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//                     WorkDate(),
//                     SalesCrMemoHeader."Currency Code",
//                     AssessableAmount,
//                     SalesCrMemoHeader."Currency Factor"),
//                     0.01,
//                     '=');

//             TotGSTAmt := Round(
//                 CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//                     WorkDate(),
//                     SalesCrMemoHeader."Currency Code",
//                     TotGSTAmt,
//                     SalesCrMemoHeader."Currency Factor"),
//                     0.01,
//                     '=');

//             DiscountAmount := Round(
//                 CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//                     WorkDate(),
//                     SalesCrMemoHeader."Currency Code",
//                     DiscountAmount,
//                     SalesCrMemoHeader."Currency Factor"),
//                     0.01,
//                     '=');
//         end;

//         CustLedgerEntry.SetCurrentKey("Document No.");
//         CustLedgerEntry.SetRange("Document No.", DocumentNo);
//         if IsInvoice then begin
//             CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
//             CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
//         end else begin
//             CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
//             CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
//         end;

//         if CustLedgerEntry.FindFirst() then begin
//             CustLedgerEntry.CalcFields("Amount (LCY)");
//             TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
//         end;

//         OtherCharges := 0;
//     end;

//     local procedure GetGSTValueForLine(
//         DocumentLineNo: Integer;
//         var CGSTLineAmount: Decimal;
//         var SGSTLineAmount: Decimal;
//         var IGSTLineAmount: Decimal)
//     var
//         DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
//     begin
//         CGSTLineAmount := 0;
//         SGSTLineAmount := 0;
//         IGSTLineAmount := 0;

//         DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
//         DetailedGSTLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
//         DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
//         if DetailedGSTLedgerEntry.FindSet() then
//             repeat
//                 CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
//             until DetailedGSTLedgerEntry.Next() = 0;

//         DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
//         if DetailedGSTLedgerEntry.FindSet() then
//             repeat
//                 SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
//             until DetailedGSTLedgerEntry.Next() = 0;

//         DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
//         if DetailedGSTLedgerEntry.FindSet() then
//             repeat
//                 IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
//             until DetailedGSTLedgerEntry.Next() = 0;
//     end;

//     procedure GenerateIRN(input: Text): Text
//     var
//         CryptographyManagement: Codeunit "Cryptography Management";
//         HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
//     begin
//         exit(CryptographyManagement.GenerateHash(input, HashAlgorithmType::SHA256));
//     end;

//     procedure GenerateAuthToken(RecSalesHeader: Record "Sales Invoice Header"): text;
//     var
//         JsonWriter: DotNet JsonTextWriter;
//         JsonWriter1: DotNet JsonTextWriter;
//         plainAppkey: text;
//         jsonString: text;
//         JsonLinq: DotNet JObject;
//         Myfile: File;
//         encryptedPayload: text;
//         Instream1: InStream;
//         encoding: DotNet Encoding;
//         GenLedSet: Record "General Ledger Setup";
//         keyTxt: text;
//         finPayload: text;
//         GSTEncr_Decr: DotNet GSTEncr_Decr;
//         JsonLinq1: DotNet JObject;
//         encryptedPass: text;
//         base64Payload: text;
//         rec_GSTRegNos: Record "GST Registration Nos.";
//         pass: label 'Barbeque@123';
//         encryptedAppKey: text;
//         bytearr: DotNet Array;
//         CU_base64: Codeunit "Base64 Convert";

//     begin

//         JsonLinq := JsonLinq.JObject();
//         jsonWriter := JsonLinq.CreateWriter();

//         Myfile.OPEN('C:\BBQ Project Extensions\CITS_RS\einv_sandbox1.pem');
//         Myfile.CREATEINSTREAM(Instream1);
//         Instream1.READTEXT(keyTxt);

//         GSTEncr_Decr := GSTEncr_Decr.RSA_AES();
//         encryptedPass := GSTEncr_Decr.EncryptAsymmetric(pass, keyTxt);

//         JsonWriter.WritePropertyName('userName');
//         JsonWriter.WriteValue('BBQBLR');

//         JsonWriter.WritePropertyName('password');
//         JsonWriter.WriteValue(pass);

//         plainAppkey := GSTEncr_Decr.RandomString(32, FALSE);

//         JsonWriter.WritePropertyName('AppKey');
//         bytearr := encoding.UTF8.GetBytes(plainAppkey);
//         JsonWriter.WriteValue(bytearr);

//         JsonWriter.WritePropertyName('ForceRefreshAuthToken');
//         JsonWriter.WriteValue('true');

//         jsonString := JsonLinq.ToString();
//         MESSAGE(jsonString);

//         //Convert to base 64 string first and then encrypt with the GST Public Key then populate the Final Json payload
//         base64Payload := CU_base64.ToBase64(jsonString);
//         Message(base64Payload);

//         encryptedPayload := GSTEncr_Decr.EncryptAsymmetric(base64Payload, keyTxt);

//         JsonLinq1 := JsonLinq1.JObject();
//         JsonWriter1 := JsonLinq1.CreateWriter();

//         JsonWriter1.WritePropertyName('Data');
//         JsonWriter1.WriteValue(encryptedPayload);

//         finPayload := JsonLinq1.ToString();
//         getAuthfromNIC(finPayload, plainAppkey, RecSalesHeader);
//         Message(finPayload);
//         exit(finPayload);
//         // exit(jsonString);
//     end;

//     procedure getAuthfromNIC(JsonString: text; PlainKey: Text; SalesHeader: Record "Sales Invoice Header")
//     var
//         genledSetup: Record "General Ledger Setup";
//         responsetxt: text;

//         glStream: DotNet StreamWriter;
//         glHTTPRequest: DotNet HttpWebRequest;
//         servicepointmanager: DotNet ServicePointManager;
//         securityprotocol: DotNet SecurityProtocolType;
//         gluriObj: DotNet Uri;
//         glReader: dotnet StreamReader;
//         glresponse: DotNet HttpWebResponse;
//     begin
//         genledSetup.GET;
//         CLEAR(glHTTPRequest);
//         servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
//         //  gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eivital/v1.03/auth');
//         // gluriObj := gluriObj.Uri(genledSetup."GST Authorization URL");
//         gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eivital/v1.04/auth');
//         glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);
//         glHTTPRequest.Headers.Add('client_id', 'AAKCS29TXP3G937');
//         glHTTPRequest.Headers.Add('client_secret', 'xDdRrf6L0Zzn42HhVvAP');
//         glHTTPRequest.Headers.Add('GSTIN', '29AAKCS3053N1ZS');
//         glHTTPRequest.Timeout(10000);
//         glHTTPRequest.Method := 'POST';
//         glHTTPRequest.ContentType := 'application/json; charset=utf-8';
//         glstream := glstream.StreamWriter(glHTTPRequest.GetRequestStream());
//         glstream.Write(JsonString);
//         glstream.Close();
//         glHTTPRequest.Timeout(10000);
//         glResponse := glHTTPRequest.GetResponse();
//         glHTTPRequest.Timeout(10000);
//         glreader := glreader.StreamReader(glResponse.GetResponseStream());
//         //  txtResponse := glreader.ReadToEnd;//Response Length exceeds the max. allowed text length in Navision 19092019
//         IF glResponse.StatusCode = 200 THEN BEGIN
//             //    encryptedSEK := ParseResponse_Auth(glreader.ReadToEnd,appKey,SIHeader);
//             // Myfile.OPEN(genledSetup."GST Public Key Directory Path");
//             // Myfile.CREATEINSTREAM(Instream);
//             // Instream.READTEXT(keyTxt);
//             responsetxt := glReader.ReadToEnd();
//             Message(responsetxt);
//             ParseAuthResponse(responsetxt, PlainKey, SalesHeader);


//             // Encoding := Encoding.UTF8Encoding();
//             // Bytes := Encoding.GetBytes(appKey);

//             // BouncyThat1 := BouncyThat1.Class1();
//             // decyptSEK := BouncyThat1.DecryptBySymmetricKey(encryptedSEK,Bytes);

//             // GSTEnc_Decr := GSTEnc_Decr.RSA_AES();
//             // decyptSEK   := GSTEnc_Decr.DecryptBySymmetricKey(encryptedSEK,Bytes);

//             /*recAuthData.RESET;
//             recAuthData.SETCURRENTKEY("Sr No.");
//             recAuthData.SETFILTER(DocumentNum,'=%1',SIHeader."No.");
//             IF recAuthData.FINDLAST THEN BEGIN
//              recAuthData.DecryptedSEK := decyptSEK;
//              recAuthData.MODIFY;
//             END;

//            glreader.Close();
//            glreader.Dispose();

//           END ELSE
//            IF glResponse.StatusCode <> 200 THEN BEGIN
//             MESSAGE(FORMAT(glResponse.StatusCode));
//             ERROR(glResponse.StatusDescription);
//            END;*/
//         END;
//     END;

//     procedure ParseAuthResponse(TextResponse: text; PlainKey: text; SIHeader: Record "Sales Invoice Header"): text;
//     var
//         message1: text;
//         CurrentObject: text;
//         CurrentElement: text;
//         ValuePair: text;
//         PlainSEK: text;
//         GSTIn_DLL: DotNet GSTEncr_Decr;
//         FormatChar: label '{}';
//         CurrentValue: text;
//         txtStatus: text;
//         p: Integer;
//         x: Integer;
//         txtAuthT: text;
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         l: Integer;
//         txtError: text;
//         txtEncSEK: text;
//         encoding: DotNet Encoding;
//         txtExpiry: text;
//         bytearr: DotNet Array;
//     begin

//         CLEAR(message1);
//         CLEAR(CurrentObject);
//         p := 0;
//         x := 1;

//         IF STRPOS(TextResponse, '{}') > 0 THEN
//             EXIT;
//         //no response

//         // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
//         // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

//         TextResponse := DELCHR(TextResponse, '=', FormatChar);
//         l := STRLEN(TextResponse);

//         WHILE p < l DO BEGIN
//             ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
//             IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
//                 p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
//                 CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
//                 CurrentElement := DELCHR(CurrentElement, '=', ':');
//                 CurrentElement := DELCHR(CurrentElement, '=', '"');

//                 CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
//                 CurrentValue := DELCHR(CurrentValue, '=', ':');
//                 CurrentValue := DELCHR(CurrentValue, '=', '"');

//                 CASE CurrentElement OF
//                     'Status':
//                         BEGIN
//                             txtStatus := CurrentValue;
//                         END;
//                     'ErrorDetails':
//                         BEGIN
//                             txtError := CurrentValue;
//                         END;
//                     'AuthToken':
//                         BEGIN
//                             txtAuthT := CurrentValue;
//                         END;
//                     'Sek':
//                         BEGIN
//                             txtEncSEK := CurrentValue;
//                         END;
//                     'TokenExpiry':
//                         BEGIN
//                             txtExpiry := CurrentValue;
//                         END;
//                 END;
//             END;
//             x := x + 1;
//         END;



//         recAuthData.RESET;
//         recAuthData.SETCURRENTKEY("Sr No.");
//         IF recAuthData.FINDLAST THEN
//             recAuthData."Sr No." += 1
//         ELSE
//             recAuthData."Sr No." := 1;
//         recAuthData."Auth Token" := txtAuthT;
//         recAuthData.SEK := txtEncSEK;
//         recAuthData."Insertion DateTime" := CurrentDateTime;
//         recAuthData."Expiry Date Time" := txtExpiry;
//         recAuthData.PlainAppKey := PlainKey;
//         recAuthData.DocumentNum := SIHeader."No.";
//         recAuthData.INSERT;

//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, SIHeader."No.");
//         if recAuthData.FindFirst() then begin
//             GSTIn_DLL := GSTIn_DLL.RSA_AES();
//             bytearr := encoding.UTF8.GetBytes(recAuthData.PlainAppKey);
//             PlainSEK := GSTIn_DLL.DecryptBySymmetricKey(recAuthData.SEK, bytearr);
//             recAuthData.DecryptedSEK := PlainKey;
//             recAuthData.Modify();
//         end;

//         EXIT(txtEncSEK);
//     end;

//     procedure Call_IRN_API(recAuthData: Record "GST E-Invoice(Auth Data)"; JsonString: text; SalesHead: record "Sales Invoice Header")
//     var
//         genledSetup: Record "General Ledger Setup";
//         glHTTPRequest: DotNet HttpWebRequest;
//         gluriObj: DotNet Uri;
//         glResponse: DotNet HttpWebResponse;
//         glstream: DotNet StreamWriter;
//         glreader: DotNet StreamReader;
//         servicepointmanager: DotNet ServicePointManager;
//         securityprotocol: DotNet SecurityProtocolType;
//         GSTEncrypt: DotNet GSTEncr_Decr;
//         signedData: text;
//         decryptedIRNResponse: text;

//     begin
//         genledSetup.GET;
//         CLEAR(glHTTPRequest);
//         servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
//         // gluriObj := gluriObj.Uri(genledSetup."GST IRN Generation URL");
//         gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eicore/v1.03/Invoice');
//         glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);
//         //   glHTTPRequest.Headers.Add('client_id',genledSetup."E-Invoice Client ID");
//         glHTTPRequest.Headers.Add('client_id', 'AAKCS29TXP3G937');
//         //   glHTTPRequest.Headers.Add('client_secret',genledSetup."E-Invoice Client Secret");
//         glHTTPRequest.Headers.Add('client_secret', 'xDdRrf6L0Zzn42HhVvAP');
//         //   glHTTPRequest.Headers.Add('gstin',GSTIN);
//         glHTTPRequest.Headers.Add('gstin', '29AAKCS3053N1ZS');
//         //   glHTTPRequest.Headers.Add('user_name',genledSetup."E-Invoice UserName");
//         glHTTPRequest.Headers.Add('user_name', 'BBQBLR');
//         glHTTPRequest.Headers.Add('authtoken', recAuthData."Auth Token");

//         glHTTPRequest.Timeout(10000);
//         glHTTPRequest.Method := 'POST';
//         glHTTPRequest.ContentType := 'application/json; charset=utf-8';
//         glstream := glstream.StreamWriter(glHTTPRequest.GetRequestStream());
//         glstream.Write(JsonString);
//         glstream.Close();
//         glHTTPRequest.Timeout(10000);
//         glResponse := glHTTPRequest.GetResponse();
//         glHTTPRequest.Timeout(10000);
//         glreader := glreader.StreamReader(glResponse.GetResponseStream());
//         //  txtResponse := glreader.ReadToEnd;//Response Length exceeds the max. allowed text length in Navision 19092019

//         IF glResponse.StatusCode = 200 THEN BEGIN
//             signedData := ParseResponse_IRN_ENCRYPT(glreader.ReadToEnd, SalesHead);

//             GSTEncrypt := GSTEncrypt.RSA_AES();
//             decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);

//             /*path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
//             File.CREATE(path);
//             File.CREATEOUTSTREAM(Outstr);
//             Outstr.WRITETEXT(decryptedIRNResponse);*/
//             ParseResponse_IRN_DECRYPT(decryptedIRNResponse, SalesHead);

//             glreader.Close();
//             glreader.Dispose();
//         END
//         ELSE
//             IF (glResponse.StatusCode <> 200) THEN BEGIN
//                 MESSAGE(FORMAT(glResponse.StatusCode));
//                 ERROR(glResponse.StatusDescription);
//             END;

//     end;

//     procedure ParseResponse_IRN_ENCRYPT(TextResponse: text; SalesHead: Record "Sales Invoice Header"): Text;
//     var
//         message1: Text;
//         CurrentObject: Text;
//         FormatChar: label '{}';
//         p: Integer;
//         l: Integer;
//         errPOS: Integer;
//         x: Integer;
//         CurrentElement: Text;
//         ValuePair: Text;
//         txtEWBNum: Text;
//         txtStatus: Text;
//         CurrentValue: Text;
//         txtError: text;
//         txtSignedData: text;
//         txtInfodDtls: text;
//     begin
//         //Get value from Json Response >>

//         CLEAR(message1);
//         CLEAR(CurrentObject);
//         p := 0;
//         x := 1;

//         IF STRPOS(TextResponse, '{}') > 0 THEN
//             EXIT;
//         //no response

//         // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
//         // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

//         TextResponse := DELCHR(TextResponse, '=', FormatChar);
//         l := STRLEN(TextResponse);
//         // MESSAGE(TextResponse);
//         errPOS := STRPOS(TextResponse, '"Status":0');
//         //  recSIHeader.RESET;
//         //  recSIHeader.SETFILTER("No.",'=%1',SalesHead."No.");
//         //  IF recSIHeader.FINDFIRST THEN BEGIN
//         //    recSIHeader."Acknowledgement No." := COPYSTR(TextResponse,1,250);
//         //   recSIHeader.MODIFY;
//         IF errPOS > 0 THEN
//             ERROR('Error in IRN generation : %1', TextResponse);

//         WHILE p < l DO BEGIN
//             ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
//             IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
//                 p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
//                 CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
//                 CurrentElement := DELCHR(CurrentElement, '=', ':');
//                 CurrentElement := DELCHR(CurrentElement, '=', '"');


//                 CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
//                 CurrentValue := DELCHR(CurrentValue, '=', ':');
//                 CurrentValue := DELCHR(CurrentValue, '=', '"');

//                 CASE CurrentElement OF
//                     'Status':
//                         BEGIN
//                             txtStatus := CurrentValue;
//                         END;
//                     'ErrorDetails':
//                         BEGIN
//                             txtError := CurrentValue;
//                         END;
//                     'Data':
//                         BEGIN
//                             txtSignedData := CurrentValue;
//                         END;
//                     'InfoDtls':
//                         BEGIN
//                             txtInfodDtls := CurrentValue;
//                         END;
//                 END;
//             END;
//             x := x + 1;
//         END;

//         EXIT(txtSignedData);

//     end;

//     procedure ParseResponse_IRN_DECRYPT(TextResponse: text; SalesHead: Record "Sales Invoice Header"): Text;
//     var
//         message1: Text;
//         CurrentObject: Text;
//         FormatChar: label '';
//         p: Integer;
//         l: Integer;
//         x: Integer;
//         CurrentElement: Text;
//         ValuePair: Text;
//         txtEWBNum: Text;
//         CurrentValue: Text;
//         txtAckNum: Text;
//         txtIRN: Text;
//         txtAckDate: Text;
//         txtSignedInvoice: Text;
//         txtSignedQR: Text;
//         txtEWBDt: text;
//         recSIHead: Record "Sales Invoice Header";
//         txtEWBValid: Text;
//         txtRemarks: Text;
//     begin
//         //Get value from Json Response >>

//         CLEAR(message1);
//         message(TextResponse);
//         CLEAR(CurrentObject);
//         p := 0;
//         x := 1;

//         IF STRPOS(TextResponse, '{}') > 0 THEN
//             EXIT;
//         //no response

//         // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
//         // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

//         TextResponse := DELCHR(TextResponse, '=', FormatChar);
//         l := STRLEN(TextResponse);

//         WHILE p < l DO BEGIN
//             ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
//             IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
//                 p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
//                 CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
//                 CurrentElement := DELCHR(CurrentElement, '=', ':');
//                 CurrentElement := DELCHR(CurrentElement, '=', '"');

//                 CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
//                 CurrentValue := DELCHR(CurrentValue, '=', ':');
//                 CurrentValue := DELCHR(CurrentValue, '=', '"');

//                 CASE CurrentElement OF
//                     'AckNo':
//                         BEGIN
//                             txtAckNum := CurrentValue;
//                         END;
//                     'AckDt':
//                         BEGIN
//                             txtAckDate := CurrentValue;
//                         END;
//                     'Irn':
//                         BEGIN
//                             txtIRN := CurrentValue;
//                         END;
//                     'SignedInvoice':
//                         BEGIN
//                             txtSignedInvoice := CurrentValue;
//                         END;
//                     'SignedQRCode':
//                         BEGIN
//                             txtSignedQR := CurrentValue;
//                         END;
//                     'EwbNo':
//                         BEGIN
//                             txtEWBNum := CurrentValue;
//                         END;
//                     'EwbDt':
//                         BEGIN
//                             txtEWBDt := CurrentValue;
//                         END;
//                     'EwbValidTill':
//                         BEGIN
//                             txtEWBValid := CurrentValue;
//                         END;
//                     'Remarks':
//                         BEGIN
//                             txtRemarks := CurrentValue;
//                         END;
//                 END;
//             END;
//             x := x + 1;
//         END;


//         recSIHead.RESET;
//         recSIHead.SETFILTER("No.", '=%1', SalesHead."No.");
//         IF recSIHead.FINDFIRST THEN BEGIN
//             // UpdateHeaderIRN(txtSignedQR, SalesHead, txtIRN, txtAckNum, txtAckDate);//23102020
//         END;

//         EXIT(txtIRN);

//     end;

//     procedure UpdateHeaderIRN(QRCodeInput: Text; AckDt: text; AckNum: Text; SalesHead: Record "Sales Invoice Header")
//     var
//         FieldRef1: FieldRef;
//         QRCodeFileName: Text;
//         TempBlob: Record TempBlob;
//         RecRef1: RecordRef;
//         IRN: text;
//         dtText: text;
//         acknwolederDate: DateTime;

//         IBarCodeProvider: DotNet BarcodeProvider;
//         FileManagement: Codeunit "File Management";
//     begin

//         GetBarCodeProvider(IBarCodeProvider);
//         QRCodeFileName := IBarCodeProvider.GetBarcode(QRCodeInput);
//         // QRCodeFileName := MoveToMagicPath(QRCodeFileName);

//         // Load the image from file into the BLOB field.
//         CLEAR(TempBlob);
//         TempBlob.CALCFIELDS(Blob);
//         // FileManagement.BLOBImport(TempBlob, QRCodeFileName);

//         //GET SI HEADER REC AND SAVE QR INTO BLOB FIELD

//         RecRef1.OPEN(112);
//         FieldRef1 := RecRef1.FIELD(3);
//         FieldRef1.SETRANGE(SalesHead."No.");//Parameter
//         IF RecRef1.FINDFIRST THEN BEGIN
//             FieldRef1 := RecRef1.FIELD(50004);//QR
//             FieldRef1.VALUE := TempBlob.Blob;
//             FieldRef1 := RecRef1.FIELD(50002);//IRN Num
//             FieldRef1.VALUE := IRN;
//             FieldRef1 := RecRef1.FIELD(50003);//AckNum
//             FieldRef1.VALUE := ACkNum;
//             FieldRef1 := RecRef1.FIELD(50006);//AckDate
//             dtText := ConvertAckDt(AckDt);
//             EVALUATE(acknwolederDate, dtText);
//             FieldRef1.VALUE := acknwolederDate;
//             RecRef1.MODIFY;
//         END;
//         // Erase the temporary file.
//         IF NOT ISSERVICETIER THEN
//             IF EXISTS(QRCodeFileName) THEN
//                 ERASE(QRCodeFileName);

//     end;

//     procedure GetBarCodeProvider(var IBarCodeProvider: DotNet BarcodeProvider)
//     var
//         QRCodeProvider: DotNet QRProvider;
//     begin
//         CLEAR(QRCodeProvider);
//         QRCodeProvider := QRCodeProvider.QRCodeProvider;
//         IBarCodeProvider := QRCodeProvider;
//     end;

//     procedure ConvertAckDt(DtText: text): text;
//     var
//     begin

//     end;



//     /*procedure MoveToMagicPath()
//     var
//     DestinationFileName:Text;
//     FileManagement:Codeunit "File Management";
//     SourceFileName:text;
//     FileSystemObject:Text;
//     begin


//         // User Temp Path
//     DestinationFileName := COPYSTR(FileManagement.ClientTempFileName(''),1,1024);
//     IF ISCLEAR(FileSystemObject) THEN
//       CREATE(FileSystemObject,TRUE,TRUE);
//     FileSystemObject.MoveFile(SourceFileName,DestinationFileName);
//     end;*/

// }

