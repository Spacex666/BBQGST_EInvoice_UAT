// codeunit 50150 E_Invoice_TransferShipments
// {
//     trigger OnRun()
//     begin

//     end;

//     var
//         SalesLinesErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Locked = true;

//         CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
//         GlobalNULL: Variant;
//         CGSTLbl: Label 'CGST', Locked = true;

//         gl_BillToPh: Code[12];
//         gl_BillToEm: Text;
//         SGSTLbl: label 'SGST', Locked = true;
//         IGSTLbl: Label 'IGST', Locked = true;
//         CESSLbl: Label 'CESS', Locked = true;
//         JsonWriter: DotNet JsonTextWriter;
//         JsonLObj: DotNet JObject;
//         DocumentNo: Code[50];
//         BBQ_GSTIN: Label '29AAKCS3053N1ZS', Locked = true;

//         OTHTxt: Label 'OTH';
//         DocumentNoBlankErr: Label 'Document No. Blank';


//     procedure GenerateIRN(TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         txtDecryptedSek: text;
//         GSTInv_DLL: DotNet GSTEncr_Decr1;
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         jsonwriter1: DotNet JsonTextWriter;
//         jsonObjectlinq: DotNet JObject;
//         encryptedIRNPayload: text;
//         finalPayload: text;
//         JObject: JsonObject;
//         GSTManagement: Codeunit "e-Invoice Management";
//         CU_Base64: Codeunit "Base64 Convert";
//         base64IRN: text;
//         CurrExRate: Integer;
//         AesManaged: DotNet "Cryptography.SymmetricAlgorithm";
//         // GSTBouncyDLL: DotNet GST_Bouncy;
//         // GST103: DotNet GST103;
//         JsonText: text;
//         recCustomer: Record Customer;
//         SalesCrMemoHeader: Record "Sales Cr.Memo Header";
//     begin

//         Clear(GlobalNULL);
//         JsonLObj := JsonLObj.JObject();
//         JsonWriter := JsonLObj.CreateWriter;
//         DocumentNo := TransferShipHeader."No.";

//         // message(format(TransferShipHeader.FieldNo("Acknowledgement Date")));
//         // message(format(TransferShipHeader.FieldNo("Acknowledgement No.")));
//         // message(format(TransferShipHeader.FieldNo("QR Code")));
//         // message(format(TransferShipHeader.FieldNo("Irn No.")));
//         // IF SalesHead.FIND('-') THEN
//         // recCustomer.Get(TransferShipHeader."Transfer-to Code");
//         // IF GSTManagement.IsGSTApplicable(TransferShipHeader."No.", 36) THEN BEGIN
//         //     IF recCustomer."GST Customer Type" IN
//         //         [recCustomer."GST Customer Type"::Unregistered,
//         //         recCustomer."GST Customer Type"::" "] THEN
//         //         ERROR('E-Invoicing is not applicable for Unregistered, Export and Deemed Export Customers.');

//         // IF TransferShipHeader."Currency Factor" <> 0 THEN
//         //     CurrExRate := 1 / TransferShipHeader."Currency Factor"
//         // ELSE
//         CurrExRate := 1;
//         // end;

//         JsonWriter.WritePropertyName('Version');//NIC API Version
//         JsonWriter.WriteValue('1.1');//Later to be provided as setup.

//         WriteTransDtls(JsonWriter, JsonLObj);
//         WriteDocDtls(JsonWriter, JsonLObj, TransferShipHeader);
//         WriteSellerDtls(TransferShipHeader, JsonWriter, JsonLObj, gl_BillToPh, gl_BillToEm);
//         WriteBuyerDtls(TransferShipHeader, JsonWriter, JsonLObj);
//         WriteItemDtls(TransferShipHeader, JsonWriter, JsonLObj);
//         WriteValDtls(TransferShipHeader, JsonWriter, JsonLObj);
//         // WriteExpDtls(JsonLObj, TransferShipHeader, JsonWriter);


//         JsonText := JsonLObj.ToString();

//         GenerateAuthToken(TransferShipHeader);//Auth Token ans Sek stored in Auth Table
//                                               //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)
//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, TransferShipHeader."No.");
//         if recAuthData.Findlast() then begin
//             // Message('DecryptedSEK %1', recAuthData.DecryptedSEK);
//             txtDecryptedSek := recAuthData.DecryptedSEK;

//             Message(JsonText);

//             GSTInv_DLL := GSTInv_DLL.RSA_AES();

//             encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);

//             // Message('Base64EncryptedIRNPayload %1', base64IRN);

//             jsonObjectlinq := jsonObjectlinq.JObject();
//             jsonwriter1 := jsonObjectlinq.CreateWriter();

//             jsonwriter1.WritePropertyName('Data');
//             jsonwriter1.WriteValue(encryptedIRNPayload);
//             // jsonwriter1.WriteValue(base64IRN);


//             finalPayload := jsonObjectlinq.ToString();
//             // Message('FinalIRNPayload %1 ', finalPayload);
//             Call_IRN_API(recAuthData, finalPayload, false, TransferShipHeader, false, false);
//         end;
//         if DocumentNo = '' then
//             //     Message(JsonText)
//             // else
//             Error(DocumentNoBlankErr);
//     end;

//     procedure GenerateAuthToken(TransferShipHeader: Record "Transfer Shipment Header"): text;
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
//         GSTEncr_Decr: DotNet GSTEncr_Decr1;
//         JsonLinq1: DotNet JObject;
//         encryptedPass: text;
//         base64Payload: text;
//         rec_GSTRegNos: Record "GST Registration Nos.";
//         pass: label 'Barbeque@123';
//         encryptedAppKey: text;
//         bytearr: DotNet Array;
//         recCustomer: Record Customer;
//         GSTRegNos: Record "GST Registration Nos.";
//         CU_base64: Codeunit "Base64 Convert";
//         recLocation: Record Location;

//     begin

//         GenLedSet.Get();
//         recLocation.Get(TransferShipHeader."Transfer-from Code");
//         GSTRegNos.Reset();
//         GSTRegNos.SetRange(Code, recLocation."GST Registration No.");
//         if GSTRegNos.FindFirst() then;
//         JsonLinq := JsonLinq.JObject();
//         jsonWriter := JsonLinq.CreateWriter();

//         // Myfile.OPEN('C:\BBQ Project Extensions\CITS_RS\einv_sandbox1.pem');
//         Myfile.OPEN(GenLedSet."GST Public Key Directory Path");
//         Myfile.CREATEINSTREAM(Instream1);
//         Instream1.READTEXT(keyTxt);

//         GSTEncr_Decr := GSTEncr_Decr.RSA_AES();
//         encryptedPass := GSTEncr_Decr.EncryptAsymmetric(pass, keyTxt);

//         JsonWriter.WritePropertyName('userName');
//         JsonWriter.WriteValue(GSTRegNos."E-Invoice UserName");

//         JsonWriter.WritePropertyName('password');
//         JsonWriter.WriteValue(GSTRegNos."E-Invoice Password");

//         plainAppkey := GSTEncr_Decr.RandomString(32, FALSE);

//         JsonWriter.WritePropertyName('AppKey');
//         // plainAppkey := 'VAVKXCHOHPMPTYEYKYQEKJOKECAVLNVP';
//         bytearr := encoding.UTF8.GetBytes(plainAppkey);
//         JsonWriter.WriteValue(bytearr);

//         JsonWriter.WritePropertyName('ForceRefreshAuthToken');
//         JsonWriter.WriteValue('true');

//         jsonString := JsonLinq.ToString();
//         // MESSAGE(jsonString);

//         //Convert to base 64 string first and then encrypt with the GST Public Key then populate the Final Json payload
//         base64Payload := CU_base64.ToBase64(jsonString);
//         // Message(base64Payload);

//         // Message('Key text %1', keyTxt);
//         encryptedPayload := GSTEncr_Decr.EncryptAsymmetric(base64Payload, keyTxt);


//         JsonLinq1 := JsonLinq1.JObject();
//         JsonWriter1 := JsonLinq1.CreateWriter();

//         JsonWriter1.WritePropertyName('Data');
//         JsonWriter1.WriteValue(encryptedPayload);

//         finPayload := JsonLinq1.ToString();
//         getAuthfromNIC(finPayload, plainAppkey, TransferShipHeader);
//         // Message(finPayload);
//         exit(finPayload);
//         // exit(jsonString);
//     end;

//     procedure WriteDocDtls(JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject;
//                                            TransShipmHeader: Record "Transfer Shipment Header")
//     var
//         Dt: Text;
//     begin
//         //***Doc Details Start
//         JsonWriter.WritePropertyName('DocDtls');
//         JsonWriter.WriteStartObject();

//         //DocType
//         JsonWriter.WritePropertyName('Typ');
//         JsonWriter.WriteValue('INV');

//         //Doc Num
//         JsonWriter.WritePropertyName('No');
//         JsonWriter.WriteValue(COPYSTR(TransShipmHeader."No.", 1, 16));

//         // Dt := FORMAT(TransShipmHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
//         Dt := FORMAT(Today - 4, 0, '<Day,2>/<Month,2>/<Year4>');
//         JsonWriter.WritePropertyName('Dt');
//         JsonWriter.WriteValue(Dt);

//         JsonWriter.WriteEndObject();
//         //***Doc Details End--
//     end;

//     procedure WriteTransDtls(JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject)
//     var
//     begin

//         JsonWriter.WritePropertyName('TranDtls');
//         JsonWriter.WriteStartObject();

//         JsonWriter.WritePropertyName('TaxSch');
//         JsonWriter.WriteValue('GST');

//         JsonWriter.WritePropertyName('SupTyp');
//         JsonWriter.WriteValue('B2B');//Where to pick this from

//         JsonWriter.WritePropertyName('RegRev');
//         JsonWriter.WriteValue('N');

//         JsonWriter.WritePropertyName('IgstOnIntra');
//         JsonWriter.WriteValue('N');

//         JsonWriter.WriteEndObject();
//     end;

//     procedure WriteSellerDtls(TransferShipHeader: Record "Transfer Shipment Header"; JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject;
//                                                                                                      gl_BilltoEm: text;
//                                                                                                      gl_BilltoPh: Code[12])
//     var
//         Loc: text;
//         Pin: Integer;
//         Stcd: Code[10];
//         Ph: Code[12];
//         Em: text;
//         Location: Record Location;
//         Gstin: Code[50];
//         CompanyInformationBuff: Record "Company Information";
//         TrdNm: text;
//         LocationBuff: Record Location;
//         LglNm: text;
//         Addr1: text;
//         Addr2: Text;
//         StateBuff: Record State;

//     begin
//         // WITH TransferShipHeader DO BEGIN
//         //   CompanyInformationBuff.GET;
//         //   LocationBuff.GET(TransferShipHeader."Transfer-from Code");
//         //   TrdNm := LocationBuff.Name;
//         //   Gstin := LocationBuff."GST Registration No.";
//         //   Bno := LocationBuff.Address;
//         //   Bnm := LocationBuff."Address 2";
//         //   Flno := '';
//         //   Loc := LocationBuff.City;
//         //   Dst := LocationBuff.City;
//         //   Pin := COPYSTR(LocationBuff."Post Code",1,6);
//         //   StateBuff.GET(LocationBuff."State Code");
//         //   Stcd := StateBuff."State Code (GST Reg. No.)";
//         //   recState.RESET;
//         //   recState.SETRANGE("State Code (GST Reg. No.)",Stcd);
//         //     IF recState.FIND('-') THEN BEGIN
//         //     Statename := recState.Description;
//         //     END;
//         //   Ph := COPYSTR(LocationBuff."Phone No.",1,10);
//         //   Em := COPYSTR(LocationBuff."E-Mail",1,50);
//         // END;

//         CLEAR(Loc);
//         CLEAR(Pin);
//         CLEAR(Stcd);
//         CLEAR(Ph);
//         CLEAR(Em);
//         WITH TransferShipHeader DO BEGIN
//             Location.GET(TransferShipHeader."Transfer-from Code");
//             //    Gstin := "Location GST Reg. No.";
//             Gstin := Location."GST Registration No.";
//             CompanyInformationBuff.GET;
//             TrdNm := Location.Name;
//             LocationBuff.GET(TransferShipHeader."Transfer-from Code");
//             LglNm := LocationBuff.Name;
//             Addr1 := LocationBuff.Address;
//             Addr2 := LocationBuff."Address 2";
//             IF Location.GET(TransferShipHeader."Transfer-from Code") THEN BEGIN
//                 Loc := Location.City;
//                 EVALUATE(Pin, COPYSTR(Location."Post Code", 1, 6));
//                 StateBuff.GET(Location."State Code");
//                 //      Stcd := StateBuff.Description;
//                 Stcd := StateBuff."State Code (GST Reg. No.)";
//                 Ph := COPYSTR(Location."Phone No.", 1, 12);
//                 gl_BilltoPh := COPYSTR(Location."Phone No.", 1, 12);
//                 gl_BilltoEm := COPYSTR(Location."E-Mail", 1, 100);
//                 Em := COPYSTR(Location."E-Mail", 1, 100);
//             END;
//         END;
//         //***Seller Details start
//         JsonWriter.WritePropertyName('SellerDtls');
//         JsonWriter.WriteStartObject();

//         JsonWriter.WritePropertyName('Gstin');
//         // JsonWriter.WriteValue(Gstin);
//         JsonWriter.WriteValue(BBQ_GSTIN);

//         //Seller Legal Name
//         JsonWriter.WritePropertyName('LglNm');
//         JsonWriter.WriteValue(LglNm);

//         //Seller Trading Name
//         JsonWriter.WritePropertyName('TrdNm');
//         JsonWriter.WriteValue(LglNm);

//         JsonWriter.WritePropertyName('Addr1');
//         JsonWriter.WriteValue(Addr1);

//         JsonWriter.WritePropertyName('Addr2');
//         JsonWriter.WriteValue(Addr2);

//         //City e.g., GANDHINAGAR
//         JsonWriter.WritePropertyName('Loc');
//         JsonWriter.WriteValue(UPPERCASE(Loc));

//         JsonWriter.WritePropertyName('Pin');
//         JsonWriter.WriteValue(Pin);

//         JsonWriter.WritePropertyName('Stcd');
//         JsonWriter.WriteValue(Stcd);

//         //Phone
//         JsonWriter.WritePropertyName('Ph');
//         JsonWriter.WriteValue(Ph);

//         //Email
//         JsonWriter.WritePropertyName('Em');
//         JsonWriter.WriteValue(Em);

//         JsonWriter.WriteEndObject();
//         //***Seller Details End--
//     END;

//     procedure WriteBuyerDtls(TransferShipHeader: Record "Transfer Shipment Header"; JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject)
//     var
//         recLoc: Record Location;
//         Gstin: Code[30];
//         TrdNm: text;
//         Addr1: text;
//         Addr2: text;
//         LglNm: text;
//         Loc: Text;
//         Dst: text;
//         Pin: Integer;
//         StateBuff: Record State;
//         recState: Record State;
//         Stcd: Code[2];
//         POS: Code[10];
//         StateName: text;
//         Ph: Code[10];
//         Em: text;
//     begin
//         WITH TransferShipHeader DO BEGIN
//             recLoc.GET(TransferShipHeader."Transfer-to Code");
//             Gstin := recLoc."GST Registration No.";
//             TrdNm := recLoc.Name;
//             LglNm := recLoc.Name;
//             Addr1 := recLoc.Address;
//             Addr2 := recLoc."Address 2";
//             Loc := recLoc.City;
//             Dst := recLoc.City;
//             EVALUATE(Pin, COPYSTR(recLoc."Post Code", 1, 6));

//             IF StateBuff.GET(recLoc."State Code") THEN BEGIN
//                 Stcd := StateBuff."State Code (GST Reg. No.)";
//                 POS := StateBuff."State Code (GST Reg. No.)";
//             END ELSE BEGIN
//                 Stcd := '';
//                 POS := ''
//             END;

//             recState.RESET();
//             recState.SETRANGE("State Code (GST Reg. No.)", Stcd);
//             IF recState.FIND('-') THEN BEGIN
//                 Statename := recState.Description;
//             END;

//             Ph := COPYSTR(recLoc."Phone No.", 1, 10);
//             Em := recLoc."E-Mail";
//         END;



//         //***Buyer Details start
//         JsonWriter.WritePropertyName('BuyerDtls');
//         JsonWriter.WriteStartObject();

//         JsonWriter.WritePropertyName('Gstin');
//         JsonWriter.WriteValue(Gstin);
//         // JsonWriter.WriteValue('29AWGPV7107B1Z1');
//         // JsonWriter.WriteValue(BBQ_GSTIN);

//         //Legal Name
//         JsonWriter.WritePropertyName('LglNm');
//         JsonWriter.WriteValue(LglNm);

//         //Trading Name
//         JsonWriter.WritePropertyName('TrdNm');
//         JsonWriter.WriteValue(TrdNm);

//         //What is this e.g., 12
//         JsonWriter.WritePropertyName('Pos');
//         JsonWriter.WriteValue(POS);

//         JsonWriter.WritePropertyName('Addr1');
//         JsonWriter.WriteValue(Addr1);

//         JsonWriter.WritePropertyName('Addr2');
//         JsonWriter.WriteValue(Addr2);

//         JsonWriter.WritePropertyName('Loc');
//         JsonWriter.WriteValue(Loc);

//         JsonWriter.WritePropertyName('Pin');
//         JsonWriter.WriteValue(Pin);

//         //What is this e.g., 29
//         JsonWriter.WritePropertyName('Stcd');
//         JsonWriter.WriteValue(Stcd);

//         //Phone
//         JsonWriter.WritePropertyName('Ph');
//         IF Ph <> '' THEN
//             JsonWriter.WriteValue(Ph)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         //Email
//         JsonWriter.WritePropertyName('Em');
//         IF Em <> '' THEN
//             JsonWriter.WriteValue(Em)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WriteEndObject();

//     end;//**Buyer Details End--

//     procedure WriteItemDtls(TransferShipHeader: Record "Transfer Shipment Header"; JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject)
//     var
//         TransferShipmentLine: Record "Transfer Shipment Line";
//         AssAmt: Decimal;
//         FreeQty: Decimal;
//         GSTRt: Decimal;
//         CgstAmt: Decimal;
//         SgstAmt: Decimal;
//         IgstAmt: Decimal;
//         CessRate: Decimal;
//         CGSTRate: Decimal;
//         SGSTRate: Decimal;
//         IGSTRate: Decimal;
//         CesAmt: Decimal;
//         CesNonAdval: Decimal;
//         StateCesRt: Decimal;
//         StateCesAmt: Decimal;
//         // StateCess:Decimal;
//         StateCesNonAdvlAmt: Decimal;
//         CU_SalesInovoice: Codeunit E_Invoice_SalesInvoice;
//         GSTBaseamt: Decimal;
//         GSTper: Decimal;
//     begin
//         TransferShipmentLine.Reset();
//         TransferShipmentLine.SETRANGE("Document No.", TransferShipHeader."No.");
//         TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
//         IF TransferShipmentLine.FINDSET THEN BEGIN
//             IF TransferShipmentLine.COUNT > 100 THEN
//                 ERROR(SalesLinesErr, TransferShipmentLine.COUNT);
//             JsonWriter.WritePropertyName('ItemList');
//             JsonWriter.WriteStartArray;
//             REPEAT
//                 if TransferShipmentLine."GST Assessable Value" <> 0 then
//                     AssAmt := TransferShipmentLine."GST Assessable Value"
//                 else
//                     AssAmt := TransferShipmentLine.Amount;
//                 FreeQty := 0;
//                 CU_SalesInovoice.GetGSTComponentRate(
//                     TransferShipHeader."No.",
//                     TransferShipmentLine."Line No.",
//                     CGSTRate,
//                     SGSTRate,
//                     IGSTRate,
//                     CessRate,
//                     CesNonAdval,
//                     StateCesAmt, GSTRt

//                 );
//                 // CU_SalesInovoice.GetGSTComponentRate(
//                 // TransferShipmentLine."Document No.",
//                 // TransferShipmentLine."Line No.",
//                 // GSTRt,
//                 // CgstAmt,
//                 // SgstAmt,
//                 // IgstAmt,
//                 // CesRt,
//                 // CesAmt,
//                 // CesNonAdval,
//                 // StateCesRt,
//                 // StateCesAmt,
//                 // StateCesNonAdvlAmt);
//                 //        Isservice := 'N';
//                 if TransferShipmentLine."GST Assessable Value" <> 0 then
//                     GSTBaseamt := TransferShipmentLine."GST Assessable Value"
//                 else
//                     GSTBaseamt := round(TransferShipmentLine.Amount, 0.01, '=');
//                 GSTper := GSTRt;
//                 // cessamount := 0;
//                 // statecessamount := 0;
//                 // statecessnonadvolamount := 0;
//                 CU_SalesInovoice.GetGSTValueForLine(TransferShipmentLine."Document No.", TransferShipmentLine."Line No.", CgstAmt, SgstAmt, IgstAmt);

//                 WriteItemTransferShip(TransferShipHeader,
//                   JsonWriter,
//                   JObject,
//                   TransferShipmentLine."Line No.",
//                   TransferShipmentLine.Description,
//                   'N',
//                   (TransferShipmentLine."HSN/SAC Code"),
//                   '',
//                   TransferShipmentLine.Quantity, FreeQty,
//                   TransferShipmentLine."Unit of Measure Code",
//                   ROUND(TransferShipmentLine."Unit Price", 0.01, '='),
//                   ROUND(TransferShipmentLine.Amount, 0.01, '='),
//                   GSTBaseamt,
//                   0,
//                   AssAmt,
//                   GSTRt,
//                   IgstAmt,
//                   CgstAmt,
//                   SgstAmt,
//                   CessRate,
//                   CesAmt,
//                   CesNonAdval,
//                   StateCesRt,
//                    StateCesAmt,
//                    StateCesNonAdvlAmt,
//                    0,
//                   (AssAmt + IgstAmt + CgstAmt + SgstAmt), TransferShipmentLine);
//             //        TransferShipmentLine."Line No.",Isservice,GSTBaseamt,GSTper,cessamount,statecessamount,statecessnonadvolamount,TransferShipmentLine."Line No.");}
//             UNTIL TransferShipmentLine.NEXT = 0;
//             JsonWriter.WriteEndArray;
//         END;
//     END;

//     procedure WriteItemTransferShip(TransferShipHeader: Record "Transfer Shipment Header";
//                       JsonWriter: DotNet JsonTextWriter;
//                       JObject: DotNet JObject;
//                       SlNo: Integer;
//                       PrdDesc: Text;
//                       IsService: Code[10];
//                       HsnCd: Code[10];
//                       Barcd: Code[50];
//                       Qty: Decimal;
//                       FreeQty: Decimal;
//                       Unit: Code[10];
//                       UnitPrice: Decimal;
//                       TotAmt: Decimal;
//                       GSTBaseamt: Decimal;
//                       Discount: Decimal;
//                       AssAmt: Decimal;
//                       GSTper: Decimal;
//                       IgstAmt: Decimal;
//                       CgstAmt: Decimal;
//                       SgstAmt: Decimal;
//                       CesRt: decimal;
//                       cessamount: Decimal;
//                       CesNonAdval: decimal;
//                       StateCes: Decimal;
//                       statecessamount: Decimal;
//                       statecessnonadvolamount: Decimal;
//                       OthChrg: Decimal;
//                       TotItemVal: Decimal;
//                       TransferShipmentLine: Record "Transfer Shipment Line")
//     var
//         recUOM: Record "Unit of Measure";
//     begin

//         JsonWriter.WriteStartObject;
//         JsonWriter.WritePropertyName('SlNo');
//         //IF PrdNm <> '' THEN
//         IF (SlNo <> 0) OR (SlNo < 999999) THEN
//             JsonWriter.WriteValue(FORMAT(SlNo))
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('PrdDesc');
//         IF PrdDesc <> '' THEN
//             JsonWriter.WriteValue(PrdDesc)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('IsServc');
//         JsonWriter.WriteValue(IsService);

//         JsonWriter.WritePropertyName('HsnCd');
//         IF HsnCd <> '' THEN
//             JsonWriter.WriteValue(HsnCd)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('Barcde');
//         IF Barcd <> '' THEN
//             JsonWriter.WriteValue(Barcd)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('Qty');
//         JsonWriter.WriteValue(Qty);

//         JsonWriter.WritePropertyName('FreeQty');
//         JsonWriter.WriteValue(FreeQty);

//         JsonWriter.WritePropertyName('Unit');
//         IF Unit <> '' THEN BEGIN
//             recUOM.GET(Unit);
//             // if recUOM."GST UOM" <> '' then
//             //     JsonWriter.WriteValue(recUOM."GST UOM")
//             // else
//             //     if recUOM.Code <> '' then
//             JsonWriter.WriteValue(recUOM.Code)
//         END ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('UnitPrice');
//         JsonWriter.WriteValue(UnitPrice);

//         JsonWriter.WritePropertyName('TotAmt');
//         JsonWriter.WriteValue(TotAmt);

//         // JsonWriter.WritePropertyName('PreTaxVal');
//         // JsonWriter.WriteValue(GSTBaseamt);

//         JsonWriter.WritePropertyName('Discount');
//         JsonWriter.WriteValue(Discount);

//         JsonWriter.WritePropertyName('AssAmt');
//         // JsonWriter.WriteValue(AssAmt);
//         JsonWriter.WriteValue(Round(AssAmt, 0.01, '='));

//         JsonWriter.WritePropertyName('GstRt');
//         JsonWriter.WriteValue(GSTper);

//         JsonWriter.WritePropertyName('IgstAmt');
//         JsonWriter.WriteValue(IgstAmt);

//         JsonWriter.WritePropertyName('CgstAmt');
//         JsonWriter.WriteValue(CgstAmt);

//         JsonWriter.WritePropertyName('SgstAmt');
//         JsonWriter.WriteValue(SgstAmt);

//         JsonWriter.WritePropertyName('CesRt');
//         JsonWriter.WriteValue(CesRt);

//         // JsonWriter.WritePropertyName('CesAmt');
//         // JsonWriter.WriteValue(cessamount);

//         JsonWriter.WritePropertyName('CesNonAdvl');
//         JsonWriter.WriteValue(CesNonAdval);

//         // JsonWriter.WritePropertyName('StateCesRt');
//         // JsonWriter.WriteValue(StateCes);

//         JsonWriter.WritePropertyName('StateCes');
//         JsonWriter.WriteValue(statecessamount);

//         // JsonWriter.WritePropertyName('StateCesNonAdvlAmt');
//         // JsonWriter.WriteValue(statecessnonadvolamount);

//         // JsonWriter.WritePropertyName('OthChrg');
//         // JsonWriter.WriteValue(OthChrg);

//         JsonWriter.WritePropertyName('TotItemVal');
//         JsonWriter.WriteValue(Round(TotItemVal, 0.01, '='));

//         // JsonWriter.WritePropertyName('OrdLineRef');
//         // JsonWriter.WriteValue(GlobalNULL);

//         // JsonWriter.WritePropertyName('OrgCntry');
//         // JsonWriter.WriteValue('91');//Hardcoded for India

//         // JsonWriter.WritePropertyName('PrdSlNo');
//         // JsonWriter.WriteValue(GlobalNULL);

//         /*recVE.RESET();
//                 recVE.SETRANGE("Document No.", TrShipmtLine."Document No.");
//                 recVE.SETRANGE("Document Line No.", TrShipmtLine."Line No.");
//                 IF recVE.FIND('-') THEN BEGIN
//                     JsonWriter.WritePropertyName('BchDtls');
//                     //    JsonWriter.WriteStartObject;
//                     JsonWriter.WriteStartArray();
//                     REPEAT
//                         ItemLedgerEntry.GET(recVE."Item Ledger Entry No.");
//                         WriteBchDtlsTransferShip(JsonWriter, JObject,
//                         COPYSTR(ItemLedgerEntry."Lot No." + ItemLedgerEntry."Serial No.", 1, 20),
//                         FORMAT(ItemLedgerEntry."Expiration Date", 0, '<Day,2>/<Month,2>/<Year4>'),
//                         FORMAT(ItemLedgerEntry."Warranty Date", 0, '<Day,2>/<Month,2>/<Year4>'));
//                     UNTIL recVE.NEXT = 0;
//                     JsonWriter.WriteEndArray();
//                     //    JsonWriter.WriteEndObject;
//                 END;

//         IF IsInvoice THEN
//         Attributedetails('','')
//         ELSE
//         Attributedetails('','');
//         */

//         JsonWriter.WriteEndObject();
//     END;

//     procedure WriteShipDtls(TransferShipHeader: Record "Transfer Shipment Header"; JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject)
//     var
//         recLoc: Record Location;
//         TrdNm: text;
//         Addr1: text;
//         Addr2: text;
//         LglNm: text;
//         Gstin: Code[20];
//         Loc: Code[10];
//         Pin: Integer;
//         StateBuff: Record State;
//         Stcd: Code[10];
//         Ph: Code[12];
//         Em: text;
//         recState: Record State;
//         Statename: text;
//     begin
//         WITH TransferShipHeader DO BEGIN
//             recLoc.GET(TransferShipHeader."Transfer-to Code");
//             Gstin := recLoc."GST Registration No.";
//             TrdNm := recLoc.Name;
//             LglNm := recLoc.Name;
//             Addr1 := recLoc.Address;
//             Addr2 := recLoc."Address 2";
//             //  Flno := '';
//             Loc := recLoc.City;
//             //  Dst := recLoc.City;
//             EVALUATE(Pin, COPYSTR(recLoc."Post Code", 1, 6));
//             IF StateBuff.GET(recLoc."State Code") THEN
//                 Stcd := StateBuff."State Code (GST Reg. No.)"
//             ELSE
//                 Stcd := '';
//             recState.SETRANGE("State Code (GST Reg. No.)", Stcd);
//             IF recState.FIND('-') THEN BEGIN
//                 Statename := recState.Description;
//             END;
//             Ph := COPYSTR(recLoc."Phone No.", 1, 10);
//             Em := COPYSTR(recLoc."E-Mail", 1, 50);
//         END;

//         JsonWriter.WritePropertyName('ShipDtls');
//         JsonWriter.WriteStartObject;

//         JsonWriter.WritePropertyName('Gstin');
//         IF Gstin <> '' THEN
//             JsonWriter.WriteValue(Gstin)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('LglNm');
//         IF LglNm <> '' THEN
//             JsonWriter.WriteValue(LglNm)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('TrdNm');
//         JsonWriter.WriteValue(TrdNm);

//         JsonWriter.WritePropertyName('Addr1');
//         IF Addr1 <> '' THEN
//             JsonWriter.WriteValue(Addr1)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);
//         JsonWriter.WritePropertyName('Addr2');
//         IF Addr2 <> '' THEN
//             JsonWriter.WriteValue(Addr2)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('Loc');
//         IF Loc <> '' THEN
//             JsonWriter.WriteValue(Loc)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WritePropertyName('Pin');
//         IF Pin <> 0 THEN
//             JsonWriter.WriteValue(Pin)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);
//         JsonWriter.WritePropertyName('Stcd');
//         IF Stcd <> '' THEN
//             JsonWriter.WriteValue(Stcd)
//         ELSE
//             JsonWriter.WriteValue(GlobalNULL);

//         JsonWriter.WriteEndObject;
//     END;

//     procedure WriteValDtls(TransferShipHeader: Record "Transfer Shipment Header"; JsonWriter: DotNet JsonTextWriter; JObject: DotNet JObject)
//     var
//         AssVal: Decimal;
//         CgstVal: Decimal;
//         SgstVal: Decimal;
//         IgstVal: Decimal;
//         CesVal: Decimal;
//         StCesVal: Decimal;
//         Disc: Decimal;
//         OthChrg: Decimal;
//         TotInvVal: Decimal;
//         RndOffAmt: Decimal;
//         CesNonAdvlAmt: decimal;
//         TotiInvValFc: Decimal;
//     begin
//         GetGSTValue(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, CesNonAdvlAmt, Disc, OthChrg, TotInvVal, TransferShipHeader);
//         //***Value Details Start
//         JsonWriter.WritePropertyName('ValDtls');
//         JsonWriter.WriteStartObject();

//         JsonWriter.WritePropertyName('Assval');
//         JsonWriter.WriteValue(AssVal);

//         JsonWriter.WritePropertyName('CgstVal');
//         JsonWriter.WriteValue(CgstVal);

//         JsonWriter.WritePropertyName('SgstVAl');
//         JsonWriter.WriteValue(SgstVal);

//         JsonWriter.WritePropertyName('IgstVal');
//         JsonWriter.WriteValue(IgstVal);

//         JsonWriter.WritePropertyName('CesVal');
//         JsonWriter.WriteValue(CesVal);

//         JsonWriter.WritePropertyName('StCesVal');
//         JsonWriter.WriteValue(StCesVal);

//         JsonWriter.WritePropertyName('CesNonAdVal');
//         JsonWriter.WriteValue(CesNonAdvlAmt);



//         JsonWriter.WritePropertyName('OthChrg');
//         JsonWriter.WriteValue(OthChrg);

//         JsonWriter.WritePropertyName('Disc');
//         JsonWriter.WriteValue(Disc);

//         // JsonWriter.WritePropertyName('RndOffAmt');
//         // JsonWriter.WriteValue(ABS(RndOffAmt));

//         JsonWriter.WritePropertyName('TotInvVal');
//         JsonWriter.WriteValue(TotInvVal);


//         // JsonWriter.WritePropertyName('TotInvValFc');
//         // JsonWriter.WriteValue(TotiInvValFc);

//         JsonWriter.WriteEndObject();
//         //***Value Details End--
//     END;

//     procedure GetGSTValue(
//        var AssessableAmount: Decimal;
//        var CGSTAmount: Decimal;
//        var SGSTAmount: Decimal;
//        var IGSTAmount: Decimal;
//        var CessAmount: Decimal;
//        var StateCessValue: Decimal;
//        var CessNonAdvanceAmount: Decimal;
//        var DiscountAmount: Decimal;
//        var OtherCharges: Decimal;
//        var TotalInvoiceValue: Decimal;
//        var TransfershipHeader: Record "Transfer Shipment Header")
//     var
//         // SalesInvoiceLine: Record "Sales Invoice Line";
//         TransferShipLine: Record "Transfer Shipment Line";
//         SalesCrMemoLine: Record "Sales Cr.Memo Line";
//         GSTLedgerEntry: Record "GST Ledger Entry";
//         DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
//         CurrencyExchangeRate: Record "Currency Exchange Rate";
//         CustLedgerEntry: Record "Cust. Ledger Entry";
//         TotGSTAmt: Decimal;
//     begin
//         GSTLedgerEntry.SetRange("Document No.", DocumentNo);

//         GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
//         if GSTLedgerEntry.Find('-') then
//             repeat
//                 CGSTAmount += Abs(GSTLedgerEntry."GST Amount");
//             until GSTLedgerEntry.Next() = 0
//         else
//             CGSTAmount := 0;

//         GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
//         if GSTLedgerEntry.Find('-') then
//             repeat
//                 SGSTAmount += Abs(GSTLedgerEntry."GST Amount")
//             until GSTLedgerEntry.Next() = 0
//         else
//             SGSTAmount := 0;

//         GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
//         if GSTLedgerEntry.Find('-') then
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

//         GSTLedgerEntry.Reset();
//         GSTLedgerEntry.SetRange("Document No.", TransfershipHeader."No.");
//         // GSTLedgerEntry.SetFilter("GST Component Code", '<>%1|<>%2|<>%3|<>%4', 'CGST', 'SGST', 'IGST', 'CESS');
//         if GSTLedgerEntry.Find('-') then
//             repeat
//                 if (GSTLedgerEntry."GST Component Code") in ['CGST', 'SGST', 'IGST', 'CESS'] then
//                     StateCessValue := 0
//                 else
//                     StateCessValue += Abs(GSTLedgerEntry."GST Amount");
//             until GSTLedgerEntry.Next() = 0;

//         // if IsInvoice then begin
//         TransferShipLine.SetRange("Document No.", DocumentNo);
//         if TransferShipLine.FindSet() then
//             repeat
//                 AssessableAmount += TransferShipLine.Amount;
//                 // DiscountAmount += TransferShipLine.disc;
//                 DiscountAmount := 0;
//             until TransferShipLine.Next() = 0;
//         TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;

//         // CLEAR(TotLineAmt);
//         // IF IsInvoice THEN BEGIN

//         TransferShipLine.SETRANGE("Document No.", TransfershipHeader."No.");
//         IF TransferShipLine.FINDSET THEN BEGIN
//             REPEAT
//                 TotalInvoiceValue += TransferShipLine.Amount;
//             //   AssVal += TransferShipLine."GST Base Amount";
//             //   TotGSTAmt += TransferShipLine."Total GST Amount";
//             //  Disc += TransferShipLine.disc

//             UNTIL TransferShipLine.NEXT = 0;
//         end;

//         // RndOffAmt :=0;

//         //   TotiInvValFc := TotLineAmt + TotGSTAmt - Disc;
//         TotalInvoiceValue := ROUND((TotalInvoiceValue + IGSTAmount + SGSTAmount + CGSTAmount), 0.01, '=');
//         AssessableAmount := ROUND(AssessableAmount, 0.01, '=');
//         TotGSTAmt := ROUND(TotGSTAmt, 0.01, '=');

//         // AssessableAmount := Round(
//         //     CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//         //       WorkDate(), TransfershipHeader."Currency Code", AssessableAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
//         // TotGSTAmt := Round(
//         //     CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//         //       WorkDate(), SalesInvoiceHeader."Currency Code", TotGSTAmt, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
//         // DiscountAmount := Round(
//         //     CurrencyExchangeRate.ExchangeAmtFCYToLCY(
//         //       WorkDate(), SalesInvoiceHeader."Currency Code", DiscountAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
//         // end;
//         /* else begin
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
//         end;*/

//         // CustLedgerEntry.SetCurrentKey("Document No.");
//         // CustLedgerEntry.SetRange("Document No.", DocumentNo);
//         // // if IsInvoice then begin
//         // CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
//         // CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
//         // end;
//         /* else begin
//             CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
//             CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
//         end;*/

//         // if CustLedgerEntry.FindFirst() then begin
//         //     CustLedgerEntry.CalcFields("Amount (LCY)");
//         //     TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
//         // end;

//         OtherCharges := 0;
//     end;

//     procedure getAuthfromNIC(JsonString: text; PlainKey: Text; TransferShipHeader: Record "Transfer Shipment Header")
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
//         recGSTREgNos: Record "GST Registration Nos.";
//         recLocation: Record Location;
//     begin
//         genledSetup.GET;
//         recLocation.Get(TransferShipHeader."Transfer-from Code");
//         recGSTREgNos.Reset();
//         recGSTREgNos.SetRange(Code, recLocation."GST Registration No.");
//         if recGSTREgNos.FindFirst() then;
//         CLEAR(glHTTPRequest);
//         servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
//         //  gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eivital/v1.03/auth');
//         // gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eivital/v1.04/auth');
//         gluriObj := gluriObj.Uri(genledSetup."GST Authorization URL");
//         glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);
//         // glHTTPRequest.Headers.Add('client_id', recGSTREgNos."E-Invoice Client ID");
//         // glHTTPRequest.Headers.Add('client_secret', recGSTREgNos."E-Invoice Client Secret");
//         // glHTTPRequest.Headers.Add('GSTIN', recGSTREgNos.Code);
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

//             responsetxt := glReader.ReadToEnd();
//             // Message(responsetxt);
//             ParseAuthResponse(responsetxt, PlainKey, TransferShipHeader);


//         END;
//     END;

//     procedure ParseAuthResponse(TextResponse: text; PlainKey: text; TransferShipHeader: Record "Transfer Shipment Header"): text;
//     var
//         message1: text;
//         CurrentObject: text;
//         CurrentElement: text;
//         ValuePair: text;
//         PlainSEK: text;
//         GSTIn_DLL: DotNet GSTEncr_Decr1;
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
//         errPOS: Integer;
//         encoding: DotNet Encoding;
//         txtExpiry: text;
//         bytearr: DotNet Array;
//     begin
//         // Message(TextResponse);

//         CLEAR(message1);
//         CLEAR(CurrentObject);
//         p := 0;
//         x := 1;

//         IF STRPOS(TextResponse, '{}') > 0 THEN
//             EXIT;

//         TextResponse := DELCHR(TextResponse, '=', FormatChar);
//         l := STRLEN(TextResponse);
//         // MESSAGE(TextResponse);
//         errPOS := STRPOS(TextResponse, '"Status":0');
//         IF errPOS > 0 THEN
//             ERROR('Error in Auth Token generation : %1', TextResponse);
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
//                             // Message('AuthToke %1', txtAuthT);
//                         END;
//                     'Sek':
//                         BEGIN
//                             txtEncSEK := CurrentValue;
//                             // Message('EncryptedSEK %1', txtEncSEK);
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
//         recAuthData.DocumentNum := TransferShipHeader."No.";
//         recAuthData.INSERT;

//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, TransferShipHeader."No.");
//         if recAuthData.Findlast() then begin
//             GSTIn_DLL := GSTIn_DLL.RSA_AES();
//             bytearr := encoding.UTF8.GetBytes(recAuthData.PlainAppKey);
//             PlainSEK := GSTIn_DLL.DecryptBySymmetricKey(recAuthData.SEK, bytearr);
//             // message('SEK 1 %1,', PlainSEK);
//             recAuthData.DecryptedSEK := PlainSEK;
//             recAuthData.Modify();
//         end;

//         EXIT(txtEncSEK);
//     end;

//     procedure Call_IRN_API(recAuthData: Record "GST E-Invoice(Auth Data)"; JsonString: text; ISIRNCancel: Boolean; TransferShipHeader: record "Transfer Shipment Header"; IsEwayBill: Boolean; ISEWayCancel: Boolean)
//     var
//         genledSetup: Record "General Ledger Setup";
//         glHTTPRequest: DotNet HttpWebRequest;
//         gluriObj: DotNet Uri;
//         glResponse: DotNet HttpWebResponse;
//         glstream: DotNet StreamWriter;
//         glreader: DotNet StreamReader;
//         servicepointmanager: DotNet ServicePointManager;
//         securityprotocol: DotNet SecurityProtocolType;
//         GSTEncrypt: DotNet GSTEncr_Decr1;
//         GSTIN: Label '29AAKCS3053N1ZS', locked = true;
//         signedData: text;
//         clientID: Label 'AAKCS29TXP3G937', Locked = true;
//         clientSecret: Label 'xDdRrf6L0Zzn42HhVvAP', locked = true;
//         txtResponse: text;
//         userName: Label 'BBQBLR', Locked = true;
//         decryptedIRNResponse: text;
//         recLocation: Record Location;
//         recGSTRegNos: Record "GST Registration Nos.";


//     begin
//         genledSetup.GET;
//         recLocation.get(TransferShipHeader."Transfer-from Code");
//         recGSTRegNos.Reset();
//         recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
//         if recGSTRegNos.FindFirst() then;
//         CLEAR(glHTTPRequest);
//         servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
//         if IsEwayBill then
//             gluriObj := gluriObj.Uri(genledSetup."E_Way Bill URL")
//         else
//             if ISIRNCancel then
//                 gluriObj := gluriObj.Uri(genledSetup."Cancel E-Invoice URL")
//             else
//                 if ISEWayCancel then
//                     gluriObj := gluriObj.Uri(genledSetup."Cancel E-Way Bill")
//                 else
//                     gluriObj := gluriObj.Uri(genledSetup."GST IRN Generation URL");


//         // gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eicore/v1.03/Invoice');
//         glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);
//         // glHTTPRequest.Headers.Add('client_id', recGSTRegNos."E-Invoice Client ID");
//         // glHTTPRequest.Headers.Add('client_secret', recGSTRegNos."E-Invoice Client Secret");
//         // glHTTPRequest.Headers.Add('gstin', recGSTRegNos.Code);
//         // glHTTPRequest.Headers.Add('user_name', recGSTRegNos."E-Invoice UserName");
//         glHTTPRequest.Headers.Add('gstin', GSTIN);
//         glHTTPRequest.Headers.Add('client_id', clientID);
//         glHTTPRequest.Headers.Add('client_secret', clientSecret);
//         if not ISEWayCancel then
//             glHTTPRequest.Headers.Add('user_name', userName);
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
//             txtResponse := glreader.ReadToEnd();

//             signedData := ParseResponse_IRN_ENCRYPT(txtResponse, ISIRNCancel, TransferShipHeader, IsEwayBill, ISEWayCancel);

//             GSTEncrypt := GSTEncrypt.RSA_AES();
//             decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);

//             /*path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
//             File.CREATE(path);
//             File.CREATEOUTSTREAM(Outstr);
//             Outstr.WRITETEXT(decryptedIRNResponse);*/
//             ParseResponse_IRN_DECRYPT(decryptedIRNResponse, ISIRNCancel, TransferShipHeader, IsEwayBill, ISEWayCancel);

//             glreader.Close();
//             glreader.Dispose();
//         END
//         ELSE
//             IF (glResponse.StatusCode <> 200) THEN BEGIN
//                 MESSAGE(FORMAT(glResponse.StatusCode));
//                 ERROR(glResponse.StatusDescription);
//             END;

//     end;

//     procedure ParseResponse_IRN_ENCRYPT(TextResponse: text; ISIRNCancel: boolean; TransferShipHeader: Record "Transfer Shipment Header"; IsEwayBill: Boolean; IsEWayCancel: boolean): Text;
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

//         // IF STRPOS(TextResponse, '{}') > 0 THEN
//         //     EXIT;

//         errPOS := STRPOS(TextResponse, '"Status":0');
//         if errPOS = 0 then
//             errPOS := StrPos(TextResponse, '"status":"0"');
//         if errPOS = 0 then
//             errPOS := StrPos(TextResponse, '"Status":"0"');

//         IF errPOS > 0 THEN
//             if IsEwayBill then
//                 ERROR('Error in E-Way Bill generation : %1', TextResponse)
//             else
//                 if IsEWayCancel then
//                     ERROR('Error in E-Way Bill cancellation : %1', TextResponse)
//                 else
//                     if ISIRNCancel then
//                         ERROR('Error in IRN cancellation : %1', TextResponse)
//                     else
//                         ERROR('Error in IRN generation : %1', TextResponse);
//         //no response

//         // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
//         // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

//         TextResponse := DELCHR(TextResponse, '=', FormatChar);
//         l := STRLEN(TextResponse);
//         // MESSAGE(TextResponse);
//         // errPOS := STRPOS(TextResponse, '"Status":0');
//         //  recSIHeader.RESET;
//         //  recSIHeader.SETFILTER("No.",'=%1',SalesHead."No.");
//         //  IF recSIHeader.FINDFIRST THEN BEGIN
//         //    recSIHeader."Acknowledgement No." := COPYSTR(TextResponse,1,250);
//         //   recSIHeader.MODIFY;



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
//                     'status':
//                         txtStatus := CurrentValue;
//                     'data':
//                         txtSignedData := CurrentValue;
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

//     procedure ParseResponse_IRN_DECRYPT(TextResponse: text; ISIRNCancel: Boolean; TransferShipHeader: Record "Transfer Shipment Header"; IsEwayBill: Boolean; IsEwayCancel: Boolean): Text;
//     var
//         message1: Text;
//         CurrentObject: Text;
//         FormatChar: label '{}';
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
//         CU_EWayBill: Codeunit E_WayBill_Transfer;
//         recTransferShipHeader: Record "Transfer Shipment Header";
//         txtCancelDate: text;
//         txtCancelEwayNum: Text;
//         errPOS: integer;
//         txtCancelEWayDt: Text;
//     begin
//         //Get value from Json Response >>

//         CLEAR(message1);
//         // message(TextResponse);
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
//                     'CancelDate':
//                         begin
//                             txtCancelDate := CurrentValue;

//                         end;
//                     'ewayBillNo':
//                         begin
//                             txtCancelEwayNum := CurrentValue;
//                         end;
//                     'cancelDate':
//                         begin
//                             txtCancelEWayDt := CurrentValue;
//                         end;

//                 END;
//             END;
//             x := x + 1;
//         END;


//         recTransferShipHeader.RESET;
//         recTransferShipHeader.SETFILTER("No.", '=%1', TransferShipHeader."No.");
//         IF recTransferShipHeader.find('-') THEN begin
//             if IsEwayBill then
//                 CU_EWayBill.UpdateHeaderIRN(txtEWBDt, txtEWBNum, txtEWBValid, TransferShipHeader)//230622
//             else
//                 if ISIRNCancel then
//                     UpdateCancelIRN_Transfer(txtIRN, txtCancelDate, TransferShipHeader)//160722
//                 else
//                     if IsEwayCancel then
//                         CU_EWayBill.UpdateEWayCancelHeader(txtCancelEwayNum, txtCancelEWayDt, TransferShipHeader)
//                     else
//                         UpdateHeaderIRN(txtSignedQR, txtIRN, txtAckDate, txtAckNum, TransferShipHeader)//23102020

//         end;
//         EXIT(txtIRN);

//     end;

//     [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransferOrderPostShipment', '', false, false)]
//     procedure CreateTransferEInvoice_ShipmentPost(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferShipmentHeader: Record "Transfer Shipment Header")
//     var
//     begin
//         if Confirm('Do you want to create E-Invoice ?', true) then begin
//             GenerateIRN(TransferShipmentHeader);
//         end;
//     end;

//     procedure UpdateHeaderIRN(QRCodeInput: Text; IRNTxt: Text; AckDt: text; AckNum: Text; TransferShipHeader: Record "Transfer Shipment Header")
//     var
//         FieldRef1: FieldRef;
//         QRCodeFileName: Text;
//         // TempBlob1: Record TempBlob;
//         RecRef1: RecordRef;
//         QRGenerator: Codeunit "QR Generator";
//         dtText: text;
//         inStr: InStream;
//         acknwolederDate: DateTime;

//         IBarCodeProvider: DotNet BarcodeProvider;
//         blobCU: Codeunit "Temp Blob";
//         pgTransferOrder: Page "Transfer Order";
//         FileManagement: Codeunit "File Management";
//     begin

//         // GetBarCodeProvider(IBarCodeProvider);
//         // QRCodeFileName := IBarCodeProvider.GetBarcode(QRCodeInput);
//         // QRCodeFileName := MoveToMagicPath(QRCodeFileName);

//         // Load the image from file into the BLOB field.
//         // CLEAR(TempBlob1);
//         // blobCU.CreateInStream(inStr);
//         // TempBlob1.CALCFIELDS(Blob);
//         // blobCU.
//         // FileManagement.BLOBImport(blobCU, QRCodeFileName);

//         //GET SI HEADER REC AND SAVE QR INTO BLOB FIELD
//         RecRef1.OPEN(5744);
//         FieldRef1 := RecRef1.FIELD(1);
//         FieldRef1.SETRANGE(TransferShipHeader."No.");//Parameter
//         IF RecRef1.FINDFIRST THEN BEGIN
//             // FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("QR Code"));//QR
//             // FieldRef1.VALUE := blobCU;// TempBlob1.Blob;
//             // FieldRef1 := RecRef1.FIELD(50000);//IRN Num
//             QRGenerator.GenerateQRCodeImage(QRCodeInput, blobCU);
//             // FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("QR Code"));//QR
//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("QR Code"));//QR
//             blobCU.ToRecordRef(RecRef1, TransferShipHeader.FieldNo("QR Code"));

//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("Irn No."));
//             FieldRef1.VALUE := IRNTxt;
//             // FieldRef1 := RecRef1.FIELD(50001);//AckNum
//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("Acknowledgement No."));
//             FieldRef1.VALUE := ACkNum;
//             // FieldRef1 := RecRef1.FIELD(50002);//AckDate
//             dtText := CU_SalesInvoice.ConvertAckDt(AckDt);
//             EVALUATE(acknwolederDate, dtText);
//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("Acknowledgement Date"));

//             FieldRef1.VALUE := acknwolederDate;
//             RecRef1.MODIFY;
//         END;
//         // Erase the temporary file.
//         IF NOT ISSERVICETIER THEN
//             IF EXISTS(QRCodeFileName) THEN
//                 ERASE(QRCodeFileName);

//     end;

//     procedure MoveToMagicPath(SourceFileName: text): text;
//     var
//         DestinationFileName: Text;
//         FileManagement: Codeunit "File Management";
//         FileSystemObject: Text;
//     begin


//         // User Temp Path
//         // DestinationFileName := COPYSTR(FileManagement.ClientTempFileName(''), 1, 1024);
//         // // IF ISCLEAR(FileSystemObject) THEN
//         // //   CREATE(FileSystemObject,TRUE,TRUE);
//         // FileManagement.MoveFile(SourceFileName, DestinationFileName);
//     end;

//     procedure CancelIRN_Transfer(recTrShipHeadr: Record "Transfer Shipment Header")
//     var
//         JsonObj1: DotNet JObject;
//         codeReason: code[2];
//         recAuthData: Record "GST E-Invoice(Auth Data)";
//         jsonString: text;
//         JsonWriter1: DotNet JsonTextWriter;
//         txtDecryptedSek: text;
//         jsonObjectlinq: DotNet JObject;
//         encryptedIRNPayload: Text;
//         finalPayload: text;
//         GSTInv_DLL: DotNet GSTEncr_Decr1;
//         jsonWriter2: DotNet JsonTextWriter;
//     begin
//         JsonObj1 := JsonObj1.JObject();
//         JsonWriter1 := JsonObj1.CreateWriter();

//         JsonWriter1.WritePropertyName('Irn');
//         JsonWriter1.WriteValue(recTrShipHeadr."Irn No.");

//         JsonWriter1.WritePropertyName('CnlRsn');
//         case recTrShipHeadr."E-Invoice Cancel Reason" of
//             recTrShipHeadr."E-Invoice Cancel Reason"::"Duplicate Order":
//                 codeReason := '1';
//             recTrShipHeadr."E-Invoice Cancel Reason"::"Data Entry Mistake":
//                 codeReason := '2';
//             recTrShipHeadr."E-Invoice Cancel Reason"::"Order Cancelled":
//                 codeReason := '3';
//             recTrShipHeadr."E-Invoice Cancel Reason"::Other:
//                 codeReason := '4';
//         end;


//         // if recTrShipHeadr."E-Invoice Cancel Reason" not in 
//         // [recTrShipHeadr."E-Invoice Cancel Reason"::"Data Entry Mistake",
//         // recTrShipHeadr."E-Invoice Cancel Reason"::"Duplicate Order",
//         // recTrShipHeadr."E-Invoice Cancel Reason"::"Order Cancelled",
//         // recTrShipHeadr."E-Invoice Cancel Reason"::Other]
//         // Case recTrShipHeadr."E-Invoice Cancel Reason" of
//         // if recTrShipHeadr."E-Invoice Cancel Reason" = recTrShipHeadr."E-Invoice Cancel Reason"::"Duplicate Order" then begin
//         //     codeReason := '1';
//         // end
//         // else
//         //     if recTrShipHeadr."E-Invoice Cancel Reason" = recTrShipHeadr."E-Invoice Cancel Reason"::"Data Entry Mistake" then begin
//         //         codeReason := '2';
//         //     end
//         //     else
//         //         if recTrShipHeadr."E-Invoice Cancel Reason" = recTrShipHeadr."E-Invoice Cancel Reason"::"Order Cancelled" then begin
//         //             codeReason := '3';
//         //         end
//         //         else
//         //             if recTrShipHeadr."E-Invoice Cancel Reason" = recTrShipHeadr."E-Invoice Cancel Reason"::Other then begin
//         //                 codeReason := '4';
//         //             end;
//         // end;
//         // codeReason:
//         JsonWriter1.WriteValue(codeReason);

//         JsonWriter1.WritePropertyName('CnlRem');
//         JsonWriter1.WriteValue(recTrShipHeadr."E-Invoice Cancel Remarks");

//         jsonString := JsonObj1.ToString();

//         GenerateAuthToken(recTrShipHeadr);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

//         recAuthData.Reset();
//         recAuthData.SetRange(DocumentNum, recTrShipHeadr."No.");
//         if recAuthData.Findlast() then begin

//             txtDecryptedSek := recAuthData.DecryptedSEK;

//             Message(jsonString);

//             GSTInv_DLL := GSTInv_DLL.RSA_AES();
//             // base64IRN := CU_Base64.ToBase64(JsonText);
//             encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

//             jsonObjectlinq := jsonObjectlinq.JObject();
//             jsonWriter2 := jsonObjectlinq.CreateWriter();

//             jsonWriter2.WritePropertyName('Data');
//             jsonWriter2.WriteValue(encryptedIRNPayload);



//             finalPayload := jsonObjectlinq.ToString();
//             // Message('FinalIRNPayload %1 ', finalPayload);
//             Call_IRN_API(recAuthData, finalPayload, true, recTrShipHeadr, false, false);

//         end;
//     end;

//     procedure UpdateCancelIRN_Transfer(txtIRN: text; txtCancelDate: text; recTrShipHeader: Record "Transfer Shipment Header")
//     var
//         TrShipHeader: Record "Transfer Shipment Header";
//         CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;

//     begin
//         TrShipHeader.Get(recTrShipHeader."No.");
//         TrShipHeader."Irn No." := txtIRN;
//         txtCancelDate := CU_SalesInvoice.ConvertAckDt(txtCancelDate);
//         evaluate(TrShipHeader."E-Invoice Cancel Date", txtCancelDate);
//         TrShipHeader.Modify();
//     end;


//     procedure GetBarCodeProvider(var IBarCodeProvider: DotNet BarcodeProvider)
//     var
//         QRCodeProvider: DotNet QRProvider;
//     begin
//         CLEAR(QRCodeProvider);
//         QRCodeProvider := QRCodeProvider.QRCodeProvider;
//         IBarCodeProvider := QRCodeProvider;
//     end;
// }
