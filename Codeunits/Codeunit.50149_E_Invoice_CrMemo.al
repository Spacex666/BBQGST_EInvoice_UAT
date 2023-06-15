

codeunit 50149 GST_Einvoice_CrMemo
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        JsonWriter: DotNet JsonTextWriter;
        gl_BillToPh: Code[12];
        JsonLObj: DotNet JObject;
        gl_BillToEm: Text;

        SalesLineErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Locked = true;
        GlobalNULL: Variant;
        CGSTLbl: Label 'CGST', Locked = true;
        SGSTLbl: label 'SGST', Locked = true;
        IGSTLbl: Label 'IGST', Locked = true;
        CESSLbl: Label 'CESS', Locked = true;

        DocumentNo: Code[50];
        BBQ_GSTIN: Label '29AAKCS3053N1ZS', Locked = true;

        OTHTxt: Label 'OTH';
        DocumentNoBlankErr: Label 'Document No. Blank';


    procedure GenerateIRN_01(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        txtDecryptedSek: text;
        GSTInv_DLL: DotNet GSTEncr_Decr1;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        jsonwriter1: DotNet JsonTextWriter;
        jsonObjectlinq: DotNet JObject;
        encryptedIRNPayload: text;
        finalPayload: text;
        JsonText: text;
        JObject: JsonObject;
        DocumentNo: Code[20];
        GSTManagement: Codeunit "e-Invoice Management";
        CU_Base64: Codeunit "Base64 Convert";
        base64IRN: text;
        CurrExRate: Integer;
        AesManaged: DotNet "Cryptography.SymmetricAlgorithm";
    // GSTBouncyDLL: DotNet GST_Bouncy;
    // GST103: DotNet GST103;
    begin
        clear(GlobalNULL);

        DocumentNo := SalesCrMemoHeader."No.";
        // message(format(SalesCrMemoHeader.FieldNo("Acknowledgement Date")));
        // message(format(SalesCrMemoHeader.FieldNo("Acknowledgement No.")));
        // message(format(SalesCrMemoHeader.FieldNo("QR Code")));
        // message(format(SalesCrMemoHeader.FieldNo("IRN Hash")));

        JsonLObj := JsonLObj.JObject();
        JsonWriter := JsonLObj.CreateWriter;

        IF GSTManagement.IsGSTApplicable(SalesCrMemoHeader."No.", 36) THEN BEGIN
            IF SalesCrMemoHeader."GST Customer Type" IN
                [SalesCrMemoHeader."GST Customer Type"::Unregistered,
                SalesCrMemoHeader."GST Customer Type"::" "] THEN
                ERROR('E-Invoicing is not applicable for Unregistered, Export and Deemed Export Customers.');

            IF SalesCrMemoHeader."Currency Factor" <> 0 THEN
                CurrExRate := 1 / SalesCrMemoHeader."Currency Factor"
            ELSE
                CurrExRate := 1;
        end;
        JsonWriter.WritePropertyName('Version');//NIC API Version
        JsonWriter.WriteValue('1.1');//Later to be provided as setup.

        WriteTransDtls(JsonLObj, SalesCrMemoHeader, JsonWriter);
        WriteDocDtls(JsonLObj, SalesCrMemoHeader, JsonWriter);
        WriteSellerDtls(JsonLObj, SalesCrMemoHeader, JsonWriter);
        WriteBuyerDtls(JsonLObj, SalesCrMemoHeader, JsonWriter, gl_BillToPh, gl_BillToEm);
        WriteItemDtls(JsonLObj, SalesCrMemoHeader, JsonWriter, CurrExRate);
        WriteValDtls(JsonLObj, SalesCrMemoHeader, JsonWriter);
        WriteExpDtls(JsonLObj, SalesCrMemoHeader, JsonWriter);


        JsonText := JsonLObj.ToString();

        GenerateAuthToken(SalesCrMemoHeader);//Auth Token ans Sek stored in Auth Table
                                             //IRN Encrypted with decrypted Sek that was AESdecrypted by Appkey(Random 32-bit)
        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, SalesCrMemoHeader."No.");
        if recAuthData.Findlast() then begin
            // Message('DecryptedSEK %1', recAuthData.DecryptedSEK);
            txtDecryptedSek := recAuthData.DecryptedSEK;
            Message(JsonText);

            GSTInv_DLL := GSTInv_DLL.RSA_AES();

            encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);

            // Message('EncryptedIRNPayload %1', encryptedIRNPayload);

            jsonObjectlinq := jsonObjectlinq.JObject();
            jsonwriter1 := jsonObjectlinq.CreateWriter();

            jsonwriter1.WritePropertyName('Data');
            jsonwriter1.WriteValue(encryptedIRNPayload);
            // jsonwriter1.WriteValue(base64IRN);


            finalPayload := jsonObjectlinq.ToString();
            // Message('FinalIRNPayload %1 ', finalPayload);
            Call_IRN_API(recAuthData, finalPayload, false, SalesCrMemoHeader);
        end;
        if DocumentNo = '' then
            //     /Message(JsonText)
            // else
            Error(DocumentNoBlankErr);

    end;

    procedure GenerateAuthToken(RecSalesCrMemo: Record "Sales Cr.Memo Header"): text;
    var
        JsonWriter: DotNet JsonTextWriter;
        JsonWriter1: DotNet JsonTextWriter;
        plainAppkey: text;
        jsonString: text;
        JsonLinq: DotNet JObject;
        Myfile: File;
        encryptedPayload: text;
        Instream1: InStream;
        encoding: DotNet Encoding;
        GenLedSet: Record "General Ledger Setup";
        keyTxt: text;
        finPayload: text;
        GSTEncr_Decr: DotNet GSTEncr_Decr1;
        JsonLinq1: DotNet JObject;
        encryptedPass: text;
        base64Payload: text;
        rec_GSTRegNos: Record "GST Registration Nos.";
        pass: label 'Barbeque@123';
        encryptedAppKey: text;
        bytearr: DotNet Array;
        recCustomer: Record Customer;
        GSTRegNos: Record "GST Registration Nos.";
        CU_base64: Codeunit "Base64 Convert";
        recLocation: Record Location;
    begin

        GenLedSet.Get();
        recLocation.Get(RecSalesCrMemo."Location Code");
        GSTRegNos.Reset();
        GSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        if GSTRegNos.FindFirst() then;
        JsonLinq := JsonLinq.JObject();
        jsonWriter := JsonLinq.CreateWriter();

        // Myfile.OPEN('C:\BBQ Project Extensions\CITS_RS\einv_sandbox1.pem');
        Myfile.OPEN(GenLedSet."GST Public Key Directory Path");
        Myfile.CREATEINSTREAM(Instream1);
        Instream1.READTEXT(keyTxt);

        GSTEncr_Decr := GSTEncr_Decr.RSA_AES();
        encryptedPass := GSTEncr_Decr.EncryptAsymmetric(pass, keyTxt);

        JsonWriter.WritePropertyName('userName');
        JsonWriter.WriteValue(GSTRegNos."E-Invoice UserName");

        JsonWriter.WritePropertyName('password');
        JsonWriter.WriteValue(GSTRegNos."E-Invoice Password");

        plainAppkey := GSTEncr_Decr.RandomString(32, FALSE);

        JsonWriter.WritePropertyName('AppKey');
        // plainAppkey := 'VAVKXCHOHPMPTYEYKYQEKJOKECAVLNVP';
        bytearr := encoding.UTF8.GetBytes(plainAppkey);
        JsonWriter.WriteValue(bytearr);

        JsonWriter.WritePropertyName('ForceRefreshAuthToken');
        JsonWriter.WriteValue('true');

        jsonString := JsonLinq.ToString();
        // MESSAGE(jsonString);

        //Convert to base 64 string first and then encrypt with the GST Public Key then populate the Final Json payload
        base64Payload := CU_base64.ToBase64(jsonString);
        // Message(base64Payload);

        // Message('Key text %1', keyTxt);
        encryptedPayload := GSTEncr_Decr.EncryptAsymmetric(base64Payload, keyTxt);


        JsonLinq1 := JsonLinq1.JObject();
        JsonWriter1 := JsonLinq1.CreateWriter();

        JsonWriter1.WritePropertyName('Data');
        JsonWriter1.WriteValue(encryptedPayload);

        finPayload := JsonLinq1.ToString();
        getAuthfromNIC(finPayload, plainAppkey, RecSalesCrMemo);
        // Message(finPayload);
        exit(finPayload);
        // exit(jsonString);
    end;

    procedure getAuthfromNIC(JsonString: text; PlainKey: Text; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        genledSetup: Record "General Ledger Setup";
        responsetxt: text;

        glStream: DotNet StreamWriter;
        glHTTPRequest: DotNet HttpWebRequest;
        servicepointmanager: DotNet ServicePointManager;
        securityprotocol: DotNet SecurityProtocolType;
        gluriObj: DotNet Uri;
        glReader: dotnet StreamReader;
        glresponse: DotNet HttpWebResponse;
        recGSTREgNos: Record "GST Registration Nos.";
        recLocation: Record Location;
    begin
        genledSetup.GET;
        recLocation.Get(SalesCrMemo."Location Code");
        recGSTREgNos.Reset();
        recGSTREgNos.SetRange(Code, recLocation."GST Registration No.");
        if recGSTREgNos.FindFirst() then;
        CLEAR(glHTTPRequest);
        servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
        //  gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eivital/v1.03/auth');
        // gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eivital/v1.04/auth');
        gluriObj := gluriObj.Uri(genledSetup."GST Authorization URL");
        glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);
        // glHTTPRequest.Headers.Add('client_id', recGSTREgNos."E-Invoice Client ID");
        // glHTTPRequest.Headers.Add('client_secret', recGSTREgNos."E-Invoice Client Secret");
        // glHTTPRequest.Headers.Add('GSTIN', recGSTREgNos.Code);
        glHTTPRequest.Headers.Add('client_id', 'AAKCS29TXP3G937');
        glHTTPRequest.Headers.Add('client_secret', 'xDdRrf6L0Zzn42HhVvAP');
        glHTTPRequest.Headers.Add('GSTIN', '29AAKCS3053N1ZS');
        glHTTPRequest.Timeout(10000);
        glHTTPRequest.Method := 'POST';
        glHTTPRequest.ContentType := 'application/json; charset=utf-8';
        glstream := glstream.StreamWriter(glHTTPRequest.GetRequestStream());
        glstream.Write(JsonString);
        glstream.Close();
        glHTTPRequest.Timeout(10000);
        glResponse := glHTTPRequest.GetResponse();
        glHTTPRequest.Timeout(10000);
        glreader := glreader.StreamReader(glResponse.GetResponseStream());
        //  txtResponse := glreader.ReadToEnd;//Response Length exceeds the max. allowed text length in Navision 19092019
        IF glResponse.StatusCode = 200 THEN BEGIN

            responsetxt := glReader.ReadToEnd();
            // Message(responsetxt);
            ParseAuthResponse(responsetxt, PlainKey, SalesCrMemo);

        END;
    END;

    procedure ParseAuthResponse(TextResponse: text; PlainKey: text; SalesCrMemo: Record "Sales Cr.Memo Header"): text;
    var
        message1: text;
        CurrentObject: text;
        CurrentElement: text;
        ValuePair: text;
        PlainSEK: text;
        GSTIn_DLL: DotNet GSTEncr_Decr1;
        FormatChar: label '{}';
        CurrentValue: text;
        txtStatus: text;
        p: Integer;
        x: Integer;
        txtAuthT: text;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        l: Integer;
        txtError: text;
        txtEncSEK: text;
        errPOS: Integer;
        encoding: DotNet Encoding;
        txtExpiry: text;
        bytearr: DotNet Array;
    begin
        // Message(TextResponse);

        CLEAR(message1);
        CLEAR(CurrentObject);
        p := 0;
        x := 1;

        IF STRPOS(TextResponse, '{}') > 0 THEN
            EXIT;

        TextResponse := DELCHR(TextResponse, '=', FormatChar);
        l := STRLEN(TextResponse);
        // MESSAGE(TextResponse);
        errPOS := STRPOS(TextResponse, '"Status":0');
        IF errPOS > 0 THEN
            ERROR('Error in Auth Token generation : %1', TextResponse);
        //no response

        // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
        // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

        TextResponse := DELCHR(TextResponse, '=', FormatChar);
        l := STRLEN(TextResponse);

        WHILE p < l DO BEGIN
            ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
            IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
                p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
                CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
                CurrentElement := DELCHR(CurrentElement, '=', ':');
                CurrentElement := DELCHR(CurrentElement, '=', '"');

                CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
                CurrentValue := DELCHR(CurrentValue, '=', ':');
                CurrentValue := DELCHR(CurrentValue, '=', '"');

                CASE CurrentElement OF
                    'Status':
                        BEGIN
                            txtStatus := CurrentValue;
                        END;
                    'ErrorDetails':
                        BEGIN
                            txtError := CurrentValue;
                        END;
                    'AuthToken':
                        BEGIN
                            txtAuthT := CurrentValue;
                            // Message('AuthToke %1', txtAuthT);
                        END;
                    'Sek':
                        BEGIN
                            txtEncSEK := CurrentValue;
                            // Message('EncryptedSEK %1', txtEncSEK);
                        END;
                    'TokenExpiry':
                        BEGIN
                            txtExpiry := CurrentValue;
                        END;
                END;
            END;
            x := x + 1;
        END;



        recAuthData.RESET;
        recAuthData.SETCURRENTKEY("Sr No.");
        IF recAuthData.FINDLAST THEN
            recAuthData."Sr No." += 1
        ELSE
            recAuthData."Sr No." := 1;
        recAuthData."Auth Token" := txtAuthT;
        recAuthData.SEK := txtEncSEK;
        recAuthData."Insertion DateTime" := CurrentDateTime;
        recAuthData."Expiry Date Time" := txtExpiry;
        recAuthData.PlainAppKey := PlainKey;
        recAuthData.DocumentNum := SalesCrMemo."No.";
        recAuthData.INSERT;

        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, SalesCrMemo."No.");
        if recAuthData.FindFirst() then begin
            GSTIn_DLL := GSTIn_DLL.RSA_AES();
            bytearr := encoding.UTF8.GetBytes(recAuthData.PlainAppKey);
            PlainSEK := GSTIn_DLL.DecryptBySymmetricKey(recAuthData.SEK, bytearr);
            // message('SEK 1 %1,', PlainSEK);
            recAuthData.DecryptedSEK := PlainSEK;
            recAuthData.Modify();
        end;

        EXIT(txtEncSEK);
    end;

    procedure WriteTransDtls(VAR JsonObj: DotNet JObject; SalesCrMemo: Record "Sales Cr.Memo Header"; VAR JsonWriter: DotNet JsonTextWriter)
    var
        category: Code[10];
        E_InvoiceHandler: Codeunit "e-Invoice Management";
        E_InvoiceHandler1: codeunit "e-Invoice Json Handler";
    begin
        //***Trans Detail Start
        JsonWriter.WritePropertyName('TranDtls');
        JsonWriter.WriteStartObject();

        JsonWriter.WritePropertyName('TaxSch');
        JsonWriter.WriteValue('GST');


        IF (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Registered)
        OR (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Exempted) THEN BEGIN
            category := 'B2B';

        END ELSE
            IF
   (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::Export) THEN BEGIN
                IF SalesCrMemo."GST Without Payment of Duty" THEN
                    category := 'EXPWOP'
                ELSE
                    category := 'EXPWP'
            END ELSE
                IF
           (SalesCrMemo."GST Customer Type" = SalesCrMemo."GST Customer Type"::"Deemed Export") THEN
                    category := 'DEXP';

        JsonWriter.WritePropertyName('SupTyp');
        JsonWriter.WriteValue(category);//Where to pick this from

        JsonWriter.WritePropertyName('RegRev');
        JsonWriter.WriteValue('N');

        // JsonWriter.WritePropertyName('EcmGstin');
        // JsonWriter.WriteValue(BBQ_GSTIN);

        JsonWriter.WritePropertyName('IgstOnIntra');
        JsonWriter.WriteValue('N');

        JsonWriter.WriteEndObject();
        //***Trans Detail End--

    end;

    procedure WriteDocDtls(VAR JsonObj: DotNet JObject; SalesCrMemo: Record "Sales Cr.Memo Header"; VAR JsonWriter: DotNet JsonTextWriter)
    var
        txtDocDate: Text[20];
        Typ: Code[20];
    begin
        IF SalesCrMemo."Invoice Type" = SalesCrMemo."Invoice Type"::Taxable THEN
            Typ := 'CRN';
        /*ELSE
            IF (SalesCrMemo."Invoice Type" = SalesCrMemo."Invoice Type"::"Debit Note") OR
            (SalesCrMemo."Invoice Type" = SalesCrMemo."Invoice Type"::Supplementary)
            THEN
                Typ := 'DBN'
            ELSE
                Typ := 'INV';*/
        txtDocDate := FORMAT(SalesCrMemo."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        // txtDocDate := FORMAT(Today - 5, 0, '<Day,2>/<Month,2>/<Year4>');

        //***Doc Details Start
        JsonWriter.WritePropertyName('DocDtls');
        JsonWriter.WriteStartObject();

        //DocType
        JsonWriter.WritePropertyName('Typ');
        JsonWriter.WriteValue(Typ);

        //Doc Num
        JsonWriter.WritePropertyName('No');
        JsonWriter.WriteValue(COPYSTR(SalesCrMemo."No.", 1, 16));

        JsonWriter.WritePropertyName('Dt');
        JsonWriter.WriteValue(txtDocDate);

        JsonWriter.WriteEndObject();
        //***Doc Details End--


    end;

    procedure WriteSellerDtls(VAR JsonObj: DotNet JObject; SalesCrMemo: Record "Sales Cr.Memo Header"; VAR JsonWriter: DotNet JsonTextWriter)
    var
        loc: code[10];
        Pin: Integer;
        Stcd: Code[10];
        Ph: Code[20];
        LocationBuff: Record Location;
        Location: Record Location;
        Em: Text[100];
        CompanyInformationBuff: Record "Company Information";
        TrdNm: Text;
        LglNm: text;
        Addr1: text;
        Addr2: text;
        StateBuff: Record State;
        Gstin: text;

    begin
        CLEAR(Loc);
        CLEAR(Pin);
        CLEAR(Stcd);
        CLEAR(Ph);
        CLEAR(Em);
        WITH SalesCrMemo DO BEGIN
            Location.GET(SalesCrMemo."Location Code");
            //    Gstin := "Location GST Reg. No.";
            Gstin := Location."GST Registration No.";
            CompanyInformationBuff.GET;
            TrdNm := CompanyInformationBuff.Name;
            LocationBuff.GET("Location Code");
            LglNm := LocationBuff.Name;
            Addr1 := LocationBuff.Address;
            Addr2 := LocationBuff."Address 2";
            IF LocationBuff.GET("Location Code") THEN BEGIN
                Loc := LocationBuff.City;
                EVALUATE(Pin, COPYSTR(LocationBuff."Post Code", 1, 6));
                StateBuff.GET(LocationBuff."State Code");
                //      Stcd := StateBuff.Description;
                Stcd := StateBuff."State Code (GST Reg. No.)";
                Ph := COPYSTR(LocationBuff."Phone No.", 1, 12);
                gl_BilltoPh := COPYSTR(LocationBuff."Phone No.", 1, 12);
                gl_BilltoEm := COPYSTR(LocationBuff."E-Mail", 1, 100);
                Em := COPYSTR(LocationBuff."E-Mail", 1, 100);
            END;
        END;

        //***Seller Details start
        JsonWriter.WritePropertyName('SellerDtls');
        JsonWriter.WriteStartObject();

        JsonWriter.WritePropertyName('Gstin');
        // JsonWriter.WriteValue(Gstin);
        JsonWriter.WriteValue(BBQ_GSTIN);

        //Seller Legal Name
        JsonWriter.WritePropertyName('LglNm');
        JsonWriter.WriteValue(LglNm);

        //Seller Trading Name
        JsonWriter.WritePropertyName('TrdNm');
        JsonWriter.WriteValue(LglNm);

        JsonWriter.WritePropertyName('Addr1');
        JsonWriter.WriteValue(Addr1);

        JsonWriter.WritePropertyName('Addr2');
        JsonWriter.WriteValue(Addr2);

        //City e.g., GANDHINAGAR
        JsonWriter.WritePropertyName('Loc');
        JsonWriter.WriteValue(UPPERCASE(Loc));

        JsonWriter.WritePropertyName('Pin');
        JsonWriter.WriteValue(Pin);

        JsonWriter.WritePropertyName('Stcd');
        JsonWriter.WriteValue(Stcd);

        //Phone
        JsonWriter.WritePropertyName('Ph');
        JsonWriter.WriteValue(Ph);

        //Email
        JsonWriter.WritePropertyName('Em');
        JsonWriter.WriteValue(Em);

        JsonWriter.WriteEndObject();
        //***Seller Details End--

    end;

    procedure WriteBuyerDtls(VAR JsonObj: DotNet JObject; SalesCrMemo: Record "Sales Cr.Memo Header"; VAR JsonWriter: DotNet JsonTextWriter; BilltoPh: Code[20]; BillToEm: Text[100])
    var
        POS: text;
        Stcd: text;
        Ph: text;
        Em: Text;
        Gstin: text;
        customerrec: Record Customer;
        Lglnm: text;
        Trdnm: text;
        Addr1: text;
        Loc: Code[10];
        Addr2: text;
        Pin: integer;
        ShipToAddr: Record "Ship-to Address";
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        StateBuff: Record State;
        Contact: Record Contact;
        recCustomer: Record Customer;
    begin



        WITH SalesCrMemo DO BEGIN
            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                Gstin := 'URP'
            ELSE BEGIN
                customerrec.GET(SalesCrMemo."Sell-to Customer No.");
                //      Gstin := "Customer GST Reg. No.";
                Gstin := customerrec."GST Registration No.";
            END;
            LglNm := "Sell-to Customer Name";
            TrdNm := "Bill-to Name";
            Addr1 := "Bill-to Address";
            Addr2 := "Bill-to Address 2";
            Loc := "Bill-to City";
            IF "GST Customer Type" <> "GST Customer Type"::Export THEN begin
                if recCustomer.Get("Sell-to Customer No.") then;
                if "Bill-to Post Code" <> '' then
                    EVALUATE(Pin, COPYSTR("Bill-to Post Code", 1, 6))
                else
                    EVALUATE(Pin, COPYSTR(recCustomer."Post Code", 1, 6))
            end;

            SalesCrMemoLine.SETRANGE("Document No.", "No.");
            SalesCrMemoLine.SETFILTER("GST Place of Supply", '<>%1', SalesCrMemoLine."GST Place of Supply"::" ");
            IF SalesCrMemoLine.FINDFIRST THEN
                IF SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Bill-to Address" THEN BEGIN
                    IF "GST Customer Type" IN
                    ["GST Customer Type"::Export]//,"GST Customer Type"::"SEZ Development","GST Customer Type"::"SEZ Unit"]
                    THEN
                        POS := '96'
                    ELSE BEGIN
                        StateBuff.RESET;
                        StateBuff.GET("GST Bill-to State Code");
                        POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                        //          Stcd := StateBuff.Description;
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                    END;

                    IF Contact.GET("Bill-to Contact No.") THEN BEGIN
                        Ph := COPYSTR(Contact."Phone No.", 1, 12);
                        Em := COPYSTR(Contact."E-Mail", 1, 100);
                    END;
                END ELSE
                    IF SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" THEN BEGIN
                        IF "GST Customer Type" IN
                            ["GST Customer Type"::Export]//,"GST Customer Type"::"SEZ Development","GST Customer Type"::"SEZ Unit"]
                        THEN
                            POS := '96'
                        ELSE BEGIN
                            StateBuff.RESET;
                            StateBuff.GET("GST Ship-to State Code");
                            POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                            Stcd := StateBuff.Description;
                        END;

                        IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                            Ph := COPYSTR(ShipToAddr."Phone No.", 1, 12);
                            Em := COPYSTR(ShipToAddr."E-Mail", 1, 100);
                        END;
                    END;
        END;

        //***Buyer Details start
        JsonWriter.WritePropertyName('BuyerDtls');
        JsonWriter.WriteStartObject();

        JsonWriter.WritePropertyName('Gstin');
        JsonWriter.WriteValue(Gstin);
        // JsonWriter.WriteValue('29AWGPV7107B1Z1');
        // JsonWriter.WriteValue(BBQ_GSTIN);

        //Legal Name
        JsonWriter.WritePropertyName('LglNm');
        JsonWriter.WriteValue(LglNm);

        //Trading Name
        JsonWriter.WritePropertyName('TrdNm');
        JsonWriter.WriteValue(TrdNm);

        //What is this e.g., 12
        JsonWriter.WritePropertyName('Pos');
        JsonWriter.WriteValue(POS);

        JsonWriter.WritePropertyName('Addr1');
        JsonWriter.WriteValue(Addr1);

        JsonWriter.WritePropertyName('Addr2');
        JsonWriter.WriteValue(Addr2);

        JsonWriter.WritePropertyName('Loc');
        JsonWriter.WriteValue(Loc);

        JsonWriter.WritePropertyName('Pin');
        JsonWriter.WriteValue(Pin);

        //What is this e.g., 29
        JsonWriter.WritePropertyName('Stcd');
        JsonWriter.WriteValue(Stcd);

        //Phone
        JsonWriter.WritePropertyName('Ph');
        IF Ph <> '' THEN
            JsonWriter.WriteValue(Ph)
        ELSE
            JsonWriter.WriteValue('9988776654');

        //Email
        JsonWriter.WritePropertyName('Em');
        IF Em <> '' THEN
            JsonWriter.WriteValue(Em)
        ELSE
            JsonWriter.WriteValue('test@gmail.com');

        JsonWriter.WriteEndObject();
        //**Buyer Details End--
    end;

    procedure WriteItemDtls(VAR JsonObj: DotNet JObject; VAR SalesCrMemo: Record "Sales Cr.Memo Header"; VAR JsonWriter: DotNet JsonTextWriter; CurrExchRt: Decimal)
    var
        AssAmt: Decimal;
        SlNo: integer;
        CGSTRate: Decimal;
        SGSTRate: Decimal;
        IGSTRate: Decimal;
        CessRate: Decimal;
        FreeQty: Decimal;
        CesNonAdval: Decimal;
        IsServc: text;
        GSTTr: Decimal;
        StateCess: Decimal;
        UOM: Code[10];
        GSTRt: Decimal;
        CgstAmt: Decimal;
        SgstAmt: Decimal;
        IgstAmt: Decimal;
        CesRt: Decimal;
        CesAmt: Decimal;
        StateCesRt: Decimal;
        StateCesAmt: Decimal;
        StateCesNonAdvlAmt: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal;
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        CLEAR(SlNo);
        SalesCrMemoLine.SETRANGE("Document No.", SalesCrMemo."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        //  SalesInvoiceLine.SETRANGE("Non-GST Line",FALSE);
        //  SalesInvoiceLine.SETFILTER(Type,'=%1',SalesInvoiceLine.Type::Item);
        IF SalesCrMemoLine.FIND('-') THEN BEGIN
            IF SalesCrMemoLine.COUNT > 100 THEN
                ERROR(SalesLineErr, SalesCrMemoLine.COUNT);
            JsonWriter.WritePropertyName('ItemList');
            JsonWriter.WriteStartArray;
            REPEAT
                SlNo += 1;
                //   {IF SalesInvoiceLine."GST On Assessable Value" THEN
                //     AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
                //   ELSE}
                if SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 then
                    AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)"
                else
                    AssAmt := SalesCrMemoLine.Amount;



                // AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)";
                //   IF SalesCrMemoLine."Free Supply" THEN
                //     FreeQty := SalesCrMemoLine.Quantity
                //   ELSE
                //     FreeQty := 0;

                //   GetGSTCompRate(
                //     SalesInvoiceLine."Document No.",
                //     SalesInvoiceLine."Line No.",
                //     GSTRt,
                //     CgstAmt,
                //     SgstAmt,
                //     IgstAmt,
                //     CesRt,
                //     CesAmt,
                //     CesNonAdval,
                //     StateCesRt,
                //     StateCesAmt,
                //     StateCesNonAdvlAmt);
                GetGSTComponentRate(
                    SalesCrMemoLine."Document No.",
                    SalesCrMemoLine."Line No.",
                    CGSTRate,
                    SGSTRate,
                    IGSTRate,
                    CessRate,
                    CesNonAdval,
                    StateCess, GSTRt
                );
                CLEAR(UOM);
                IF SalesCrMemoLine."Unit of Measure Code" <> '' THEN
                    UOM := COPYSTR(SalesCrMemoLine."Unit of Measure Code", 1, 8)
                ELSE
                    UOM := OTHTxt;
                IF SalesCrMemoLine."GST Group Type" = SalesCrMemoLine."GST Group Type"::Service THEN
                    IsServc := 'Y'
                ELSE
                    IsServc := 'N';
                // WriteItem(
                //   SalesInvoiceLine.Description + SalesInvoiceLine."Description 2",
                //   SalesInvoiceLine."HSN/SAC Code",
                //   SalesInvoiceLine.Quantity,
                //   FreeQty,
                //   UOM,
                //   SalesInvoiceLine."Unit Price",
                //   SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                //   SalesInvoiceLine."Line Discount Amount",
                //   SalesInvoiceLine."Line Amount",
                //   AssAmt,
                //   CGSTRate,
                //   IGSTRate,
                //   IgstAmt,
                //   StateCesRt,
                //   CesAmt,
                //   CesNonAdval,
                //   StateCesRt,
                //   StateCesAmt,
                //   StateCesNonAdvlAmt,
                //   0,
                //   SalesInvoiceLine."Amount Including Tax" + SalesInvoiceLine."Total GST Amount",
                //   SalesInvoiceLine."Line No.",
                //   SlNo,
                //   IsServc, JsonWriter, CurrExchRt, GSTRt);

                GetGSTValueForLine(SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.", CGSTValue, SGSTValue, IGSTValue);

                WriteItem(
                        SalesCrMemoLine.Description + SalesCrMemoLine."Description 2", '',
                        SalesCrMemoLine."HSN/SAC Code", '',
                        SalesCrMemoLine.Quantity, FreeQty,
                        CopyStr(SalesCrMemoLine."Unit of Measure Code", 1, 3),
                        SalesCrMemoLine."Unit Price",
                        SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount",
                        SalesCrMemoLine."Line Discount Amount", 0,
                        AssAmt, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess,
                        (AssAmt + CGSTValue + SGSTValue + IGSTValue),
                        SlNo,
                        IsServc,
                        CurrExchRt,
                        GSTRt, CGSTValue, SGSTValue, IGSTValue);

            UNTIL SalesCrMemoLine.NEXT = 0;
            JsonWriter.WriteEndArray;
        END;

    end;

    // procedure WriteItem(PrdDesc: Text; HsnCd: Text; Qty: Decimal; FreeQty: Decimal; Unit: Text; UnitPrice: Decimal; TotAmt: Decimal; Discount: Decimal; PreTaxVal: Decimal; AssAmt: Decimal; CgstAmt: Decimal; SgstAmt: Decimal; IgstAmt: Decimal; CesRt: Decimal; CesAmt: Decimal; CesNonAdval: Decimal; StateCes: Decimal; StateCesAmt: Decimal; StateCesNonAdvlAmt: Decimal; OthChrg: Decimal; TotItemVal: Decimal; SILineNo: Decimal; SlNo: Integer; IsServc: Text; VAR JsonTextWriter: DotNet JsonTextWriter; CurrExRate: Decimal; GSTRt: Decimal)
    // var
    // begin

    // end;
    local procedure WriteItem(
        ProductName: Text;
        ProductDescription: Text;
        HSNCode: Text[10];
        BarCode: Text[30];
        Quantity: Decimal;
        FreeQuantity: Decimal;
        Unit: Text[3];
        UnitPrice: Decimal;
        TotAmount: Decimal;
        Discount: Decimal;
        OtherCharges: Decimal;
        AssessableAmount: Decimal;
        CGSTRate: Decimal;
        SGSTRate: Decimal;
        IGSTRate: Decimal;
        CESSRate: Decimal;
        CessNonAdvanceAmount: Decimal;
        StateCess: Decimal;
        TotalItemValue: Decimal;
        SlNo: Integer;
        IsServc: Code[2];
        CurrExRate: Decimal;
        GSTRt: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal)
    var
    begin

        JsonWriter.WriteStartObject;

        JsonWriter.WritePropertyName('SlNo');
        JsonWriter.WriteValue(FORMAT(SlNo));

        JsonWriter.WritePropertyName('PrdDesc');
        IF ProductName <> '' THEN
            JsonWriter.WriteValue(ProductName)
        ELSE
            JsonWriter.WriteValue(GlobalNULL);


        JsonWriter.WritePropertyName('IsServc');
        IF IsServc <> '' THEN
            JsonWriter.WriteValue(IsServc)
        ELSE
            JsonWriter.WriteValue(GlobalNULL);

        JsonWriter.WritePropertyName('HsnCd');
        IF HSNCode <> '' THEN
            JsonWriter.WriteValue(HSNCode)
        ELSE
            JsonWriter.WriteValue(GlobalNULL);

        // IF IsInvoice THEN
        // InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Invoice Line",0,DocumentNo,'',0,SILineNo)
        // ELSE
        // InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Cr.Memo Line",0,DocumentNo,'',0,SILineNo);
        // ValueEntryRelation.SETCURRENTKEY("Source RowId");
        // ValueEntryRelation.SETRANGE("Source RowId",InvoiceRowID);
        // IF ValueEntryRelation.FINDSET THEN BEGIN
        // xLotNo := '';
        // JsonTextWriter.WritePropertyName('BchDtls');
        // JsonTextWriter.WriteStartObject;
        // REPEAT
        //     ValueEntry.GET(ValueEntryRelation."Value Entry No.");
        //     ItemLedgerEntry.SETCURRENTKEY("Item No.",Open,"Variant Code",Positive,"Lot No.","Serial No.");
        //     ItemLedgerEntry.GET(ValueEntry."Item Ledger Entry No.");
        //     IF xLotNo <> ItemLedgerEntry."Lot No." THEN BEGIN
        //     WriteBchDtls(
        //         COPYSTR(ItemLedgerEntry."Lot No.",1,20),
        //         FORMAT(ItemLedgerEntry."Expiration Date",0,'<Day,2>/<Month,2>/<Year4>'),
        //         FORMAT(ItemLedgerEntry."Warranty Date",0,'<Day,2>/<Month,2>/<Year4>'));
        //     xLotNo := ItemLedgerEntry."Lot No.";
        //     END;
        // UNTIL ValueEntryRelation.NEXT = 0;
        // JsonTextWriter.WriteEndObject;
        // END;


        JsonWriter.WritePropertyName('Barcde');
        JsonWriter.WriteValue('null');

        JsonWriter.WritePropertyName('Qty');
        JsonWriter.WriteValue(Quantity);
        JsonWriter.WritePropertyName('FreeQty');
        JsonWriter.WriteValue(FreeQuantity);

        JsonWriter.WritePropertyName('Unit');
        IF Unit <> '' THEN BEGIN
            IF Unit = 'KG' THEN
                Unit := 'KGS';
            JsonWriter.WriteValue(Unit)
        END ELSE
            JsonWriter.WriteValue(GlobalNULL);

        JsonWriter.WritePropertyName('UnitPrice');
        JsonWriter.WriteValue(UnitPrice * CurrExRate);

        JsonWriter.WritePropertyName('TotAmt');
        JsonWriter.WriteValue(TotAmount);// * CurrExRate);

        JsonWriter.WritePropertyName('Discount');
        JsonWriter.WriteValue(Discount);//* CurrExRate);

        // JsonWriter.WritePropertyName('PreTaxVal');
        // JsonWriter.WriteValue(PreTaxVal * CurrExRate);

        JsonWriter.WritePropertyName('AssAmt');
        JsonWriter.WriteValue(Round(AssessableAmount, 0.01, '='));
        // JsonWriter.WriteValue(AssessableAmount);// * CurrExRate);

        JsonWriter.WritePropertyName('GstRt');
        JsonWriter.WriteValue(GSTRt);

        JsonWriter.WritePropertyName('IgstAmt');
        JsonWriter.WriteValue(IGSTValue);

        JsonWriter.WritePropertyName('CgstAmt');
        JsonWriter.WriteValue(CGSTValue);

        JsonWriter.WritePropertyName('SgstAmt');
        JsonWriter.WriteValue(SGSTValue);

        JsonWriter.WritePropertyName('CesRt');
        JsonWriter.WriteValue(CESSRate);

        // JsonWriter.WritePropertyName('CesAmt');
        // JsonWriter.WriteValue(CesAmt);

        // JsonWriter.WritePropertyName('CesNonAdvlAmt');
        // JsonWriter.WriteValue(CessNonAdvanceAmount);

        JsonWriter.WritePropertyName('CesNonAdvl');
        JsonWriter.WriteValue(CessNonAdvanceAmount);

        // JsonWriter.WritePropertyName('StateCesRt');
        // JsonWriter.WriteValue(StateCes);

        JsonWriter.WritePropertyName('StateCes');
        JsonWriter.WriteValue(StateCess);

        // JsonWriter.WritePropertyName('StateCesAmt');
        // JsonWriter.WriteValue(StateCesAmt);

        // JsonWriter.WritePropertyName('StateCesNonAdvlAmt');
        // JsonWriter.WriteValue(CessNonAdvanceAmount);

        JsonWriter.WritePropertyName('TotItemVal');
        JsonWriter.WriteValue(TotalItemValue);// * CurrExRate);

        // JsonTextWriter.WritePropertyName('OthChrg');
        // JsonTextWriter.WriteValue(OthChrg);

        // JsonTextWriter.WritePropertyName('OrdLineRef');
        // JsonTextWriter.WriteValue(GlobalNULL);

        // JsonTextWriter.WritePropertyName('OrgCntry');
        // JsonTextWriter.WriteValue('IN');

        // JsonTextWriter.WritePropertyName('PrdSlNo');
        // JsonTextWriter.WriteValue(GlobalNULL);

        JsonWriter.WriteEndObject;

    end;




    local procedure GetGSTComponentRate(
        DocumentNo: Code[20];
        LineNo: Integer;
        var CGSTRate: Decimal;
        var SGSTRate: Decimal;
        var IGSTRate: Decimal;
        var CessRate: Decimal;
        var CessNonAdvanceAmount: Decimal;
        var StateCess: Decimal;
        var GSTRate: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);

        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            CGSTRate := DetailedGSTLedgerEntry."GST %";
            GSTRate := DetailedGSTLedgerEntry."GST %"
        end else
            CGSTRate := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            SGSTRate := DetailedGSTLedgerEntry."GST %";
            GSTRate := DetailedGSTLedgerEntry."GST %"
        end else
            SGSTRate := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            IGSTRate := DetailedGSTLedgerEntry."GST %";
            GSTRate := DetailedGSTLedgerEntry."GST %"
        end else
            IGSTRate := 0;

        CessRate := 0;
        CessNonAdvanceAmount := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            if DetailedGSTLedgerEntry."GST %" > 0 then
                CessRate := DetailedGSTLedgerEntry."GST %"
            else
                CessNonAdvanceAmount := Abs(DetailedGSTLedgerEntry."GST Amount");

        StateCess := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code");
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                if not (DetailedGSTLedgerEntry."GST Component Code" in [CGSTLbl, SGSTLbl, IGSTLbl, CESSLbl])
                then
                    StateCess := DetailedGSTLedgerEntry."GST %";
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    local procedure GetGSTValue(
        var AssessableAmount: Decimal;
        var CGSTAmount: Decimal;
        var SGSTAmount: Decimal;
        var IGSTAmount: Decimal;
        var CessAmount: Decimal;
        var StateCessValue: Decimal;
        var CessNonAdvanceAmount: Decimal;
        var DiscountAmount: Decimal;
        var OtherCharges: Decimal;
        var TotalInvoiceValue: Decimal;
        var SalesCrMemo: Record "Sales Cr.Memo Header"
        )
    var
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TotGSTAmt: Decimal;
    begin
        GSTLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");

        GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                CGSTAmount += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0
        else
            CGSTAmount := 0;

        GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                SGSTAmount += Abs(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.Next() = 0
        else
            SGSTAmount := 0;

        GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                IGSTAmount += Abs(GSTLedgerEntry."GST Amount")
            until GSTLedgerEntry.Next() = 0
        else
            IGSTAmount := 0;

        CessAmount := 0;
        CessNonAdvanceAmount := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            repeat
                if DetailedGSTLedgerEntry."GST %" > 0 then
                    CessAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
                else
                    CessNonAdvanceAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        GSTLedgerEntry.Reset();
        GSTLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
        // GSTLedgerEntry.SetFilter("GST Component Code", '<>%1|<>%2|<>%3|<>%4', 'CGST', 'SGST', 'IGST', 'CESS');
        if GSTLedgerEntry.Find('-') then
            repeat
                if (GSTLedgerEntry."GST Component Code") in ['CGST', 'SGST', 'IGST', 'CESS'] then
                    StateCessValue := 0
                else
                    StateCessValue += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        // if IsInvoice then begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemo."No.");
        if SalesCrMemoLine.Find('-') then
            repeat
                AssessableAmount += SalesCrMemoLine.Amount;
                DiscountAmount += SalesCrMemoLine."Inv. Discount Amount";
            until SalesCrMemoLine.Next() = 0;
        TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;

        AssessableAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesCrMemo."Currency Code", AssessableAmount, SalesCrMemo."Currency Factor"), 0.01, '=');
        TotGSTAmt := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesCrMemo."Currency Code", TotGSTAmt, SalesCrMemo."Currency Factor"), 0.01, '=');
        DiscountAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesCrMemo."Currency Code", DiscountAmount, SalesCrMemo."Currency Factor"), 0.01, '=');

        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Customer No.", SalesCrMemo."Bill-to Customer No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
        end;
        // end;
        /*else begin
           SalesCrMemoLine.SetRange("Document No.", SalesCrMemo."No.");
           if SalesCrMemoLine.FindSet() then begin
               repeat
                   AssessableAmount += SalesCrMemoLine.Amount;
                   DiscountAmount += SalesCrMemoLine."Inv. Discount Amount";
               until SalesCrMemoLine.Next() = 0;
               TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;
           end;

           AssessableAmount := Round(
               CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                   WorkDate(),
                   SalesCrMemo."Currency Code",
                   AssessableAmount,
                   SalesCrMemo."Currency Factor"),
                   0.01,
                   '=');

           TotGSTAmt := Round(
               CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                   WorkDate(),
                   SalesCrMemo."Currency Code",
                   TotGSTAmt,
                   SalesCrMemo."Currency Factor"),
                   0.01,
                   '=');

           DiscountAmount := Round(
               CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                   WorkDate(),
                   SalesCrMemo."Currency Code",
                   DiscountAmount,
                   SalesCrMemo."Currency Factor"),
                   0.01,
                   '=');
           //   end;

           CustLedgerEntry.SetCurrentKey("Document No.");
           CustLedgerEntry.SetRange("Document No.", SalesCrMemo."No.");
           CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
           CustLedgerEntry.SetRange("Customer No.", SalesCrMemo."Bill-to Customer No.");
           if CustLedgerEntry.FindFirst() then begin
               CustLedgerEntry.CalcFields("Amount (LCY)");
               TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
           end;
           //   if IsInvoice then begin
           //       CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
           //       CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
           //   end;
           //  else begin

           // end;*/



        OtherCharges := 0;
    end;

    local procedure GetGSTValueForLine(
        DocumentNo: Code[80];
        DocumentLineNo: Integer;
        var CGSTLineAmount: Decimal;
        var SGSTLineAmount: Decimal;
        var IGSTLineAmount: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        CGSTLineAmount := 0;
        SGSTLineAmount := 0;
        IGSTLineAmount := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure WriteValDtls(
        JsonObj1: DotNet JObject;
                      SalesCrMemo: Record "Sales Cr.Memo Header";
                      JsonWriter1: DotNet JsonTextWriter
    )
    var
        AssessableAmount: Decimal;
        CGSTAmount: Decimal;
        SGSTAmount: Decimal;
        IGSTAmount: Decimal;
        CessAmount: Decimal;
        StateCessAmount: Decimal;
        CESSNonAvailmentAmount: Decimal;
        DiscountAmount: Decimal;
        OtherCharges: Decimal;
        TotalInvoiceValue: Decimal;

    begin
        GetGSTValue(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue, SalesCrMemo);

        JsonWriter.WritePropertyName('ValDtls');
        JsonWriter.WriteStartObject();
        JsonWriter.WritePropertyName('Assval');
        JsonWriter.WriteValue(AssessableAmount);

        JsonWriter.WritePropertyName('CgstVal');
        JsonWriter.WriteValue(CGSTAmount);

        JsonWriter.WritePropertyName('SgstVAl');
        JsonWriter.WriteValue(SGSTAmount);

        JsonWriter.WritePropertyName('IgstVal');
        JsonWriter.WriteValue(IGSTAmount);

        JsonWriter.WritePropertyName('CesVal');
        JsonWriter.WriteValue(CessAmount);

        JsonWriter.WritePropertyName('StCesVal');
        JsonWriter.WriteValue(StateCessAmount);

        JsonWriter.WritePropertyName('CesNonAdVal');
        JsonWriter.WriteValue(CESSNonAvailmentAmount);

        JsonWriter.WritePropertyName('OthChrg');
        JsonWriter.WriteValue(OtherCharges);


        JsonWriter.WritePropertyName('Disc');
        JsonWriter.WriteValue(DiscountAmount);

        JsonWriter.WritePropertyName('TotInvVal');
        JsonWriter.WriteValue(TotalInvoiceValue);

        JsonWriter.WriteEndObject();

    end;

    procedure WriteExpDtls(JsonObj1: DotNet JObject; SalesCrMemo: Record "Sales Cr.Memo Header";
                                         JsonWriter1: DotNet JsonTextWriter)
    var
        ExportCategory: code[20];
        DocumentAmount: Decimal;
        // SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        WithPayOfDuty: Code[2];
        ShipmentBillNo: Code[20];
        ExitPort: code[10];
        ShipmentBillDate: text;
        CurrencyCode: code[3];
        CountryCode: code[2];
    begin
        if not (SalesCrMemo."GST Customer Type" in [
            SalesCrMemo."GST Customer Type"::Export,
            SalesCrMemo."GST Customer Type"::"Deemed Export",
            SalesCrMemo."GST Customer Type"::"SEZ Unit",
            SalesCrMemo."GST Customer Type"::"SEZ Development"])
        then
            exit;

        case SalesCrMemo."GST Customer Type" of
            SalesCrMemo."GST Customer Type"::Export:
                ExportCategory := 'DIR';
            SalesCrMemo."GST Customer Type"::"Deemed Export":
                ExportCategory := 'DEM';
            SalesCrMemo."GST Customer Type"::"SEZ Unit":
                ExportCategory := 'SEZ';
            SalesCrMemo."GST Customer Type"::"SEZ Development":
                ExportCategory := 'SED';
        end;

        if SalesCrMemo."GST Without Payment of Duty" then
            WithPayOfDuty := 'N'
        else
            WithPayOfDuty := 'Y';

        ShipmentBillNo := CopyStr(SalesCrMemo."Bill Of Export No.", 1, 16);
        ShipmentBillDate := Format(SalesCrMemo."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        ExitPort := SalesCrMemo."Exit Point";

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemo."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                DocumentAmount := DocumentAmount + SalesCrMemoLine.Amount;
            until SalesCrMemoLine.Next() = 0;

        CurrencyCode := CopyStr(SalesCrMemo."Currency Code", 1, 3);
        CountryCode := CopyStr(SalesCrMemo."Bill-to Country/Region Code", 1, 2);

        JsonWriter.WritePropertyName('ExpDtls');
        JsonWriter.WriteStartObject();

        JsonWriter.WritePropertyName('ExpCat');
        JsonWriter.WriteValue(ExportCategory);

        JsonWriter.WritePropertyName('WithPay');
        JsonWriter.WriteValue(WithPayOfDuty);

        JsonWriter.WritePropertyName('ShipBNo');
        JsonWriter.WriteValue(ShipmentBillNo);

        JsonWriter.WritePropertyName('ShipBDt');
        JsonWriter.WriteValue(ShipmentBillDate);

        JsonWriter.WritePropertyName('Port');
        JsonWriter.WriteValue(ExitPort);

        JsonWriter.WritePropertyName('InvForCur');
        JsonWriter.WriteValue(DocumentAmount);

        JsonWriter.WritePropertyName('ForCur');
        JsonWriter.WriteValue(CurrencyCode);

        JsonWriter.WritePropertyName('CntCode');
        JsonWriter.WriteValue(CountryCode);

        JsonWriter.WriteEndObject();
    end;

    procedure Call_IRN_API(recAuthData: Record "GST E-Invoice(Auth Data)"; JsonString: text; ISIRNCancel: Boolean; SalesCrMemo: record "Sales Cr.Memo Header")
    var
        genledSetup: Record "General Ledger Setup";
        glHTTPRequest: DotNet HttpWebRequest;
        gluriObj: DotNet Uri;
        glResponse: DotNet HttpWebResponse;
        glstream: DotNet StreamWriter;
        glreader: DotNet StreamReader;
        servicepointmanager: DotNet ServicePointManager;
        securityprotocol: DotNet SecurityProtocolType;
        GSTEncrypt: DotNet GSTEncr_Decr1;
        GSTIN: Label '29AAKCS3053N1ZS', locked = true;
        signedData: text;
        clientID: Label 'AAKCS29TXP3G937', Locked = true;
        clientSecret: Label 'xDdRrf6L0Zzn42HhVvAP', locked = true;
        userName: Label 'BBQBLR', Locked = true;
        decryptedIRNResponse: text;
        recLocation: Record Location;
        recGSTRegNos: Record "GST Registration Nos.";


    begin
        genledSetup.GET;
        recLocation.get(SalesCrMemo."Location Code");

        recGSTRegNos.Reset();
        recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        if recGSTRegNos.FindFirst() then;
        CLEAR(glHTTPRequest);
        servicepointmanager.SecurityProtocol := securityprotocol.Tls12;

        if not ISIRNCancel then
            gluriObj := gluriObj.Uri(genledSetup."GST IRN Generation URL")
        else
            gluriObj := gluriObj.Uri(genledSetup."Cancel E-Invoice URL");

        glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);

        // glHTTPRequest.Headers.Add('client_id', recGSTRegNos."E-Invoice Client ID");
        // glHTTPRequest.Headers.Add('client_secret', recGSTRegNos."E-Invoice Client Secret");
        // glHTTPRequest.Headers.Add('gstin', recGSTRegNos.Code);
        // glHTTPRequest.Headers.Add('user_name', recGSTRegNos."E-Invoice UserName");
        glHTTPRequest.Headers.Add('gstin', GSTIN);
        glHTTPRequest.Headers.Add('client_id', clientID);
        glHTTPRequest.Headers.Add('client_secret', clientSecret);
        glHTTPRequest.Headers.Add('user_name', userName);
        glHTTPRequest.Headers.Add('authtoken', recAuthData."Auth Token");

        glHTTPRequest.Timeout(10000);
        glHTTPRequest.Method := 'POST';
        glHTTPRequest.ContentType := 'application/json; charset=utf-8';
        glstream := glstream.StreamWriter(glHTTPRequest.GetRequestStream());
        glstream.Write(JsonString);
        glstream.Close();
        glHTTPRequest.Timeout(10000);
        glResponse := glHTTPRequest.GetResponse();
        glHTTPRequest.Timeout(10000);
        glreader := glreader.StreamReader(glResponse.GetResponseStream());
        //  txtResponse := glreader.ReadToEnd;//Response Length exceeds the max. allowed text length in Navision 19092019

        IF glResponse.StatusCode = 200 THEN BEGIN
            signedData := ParseResponse_IRN_ENCRYPT(glreader.ReadToEnd, ISIRNCancel, SalesCrMemo);

            GSTEncrypt := GSTEncrypt.RSA_AES();
            decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);

            // path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
            // File.CREATE(path);
            // File.CREATEOUTSTREAM(Outstr);
            // Outstr.WRITETEXT(decryptedIRNResponse);
            ParseResponse_IRN_DECRYPT(decryptedIRNResponse, ISIRNCancel, SalesCrMemo);

            glreader.Close();
            glreader.Dispose();
        END
        ELSE
            IF (glResponse.StatusCode <> 200) THEN BEGIN
                MESSAGE(FORMAT(glResponse.StatusCode));
                ERROR(glResponse.StatusDescription);
            END;

    end;

    procedure ParseResponse_IRN_ENCRYPT(TextResponse: text; ISIrnCancel: Boolean; SalesCrMemo: Record "Sales Cr.Memo Header"): Text;
    var
        message1: Text;
        CurrentObject: Text;
        FormatChar: label '{}';
        p: Integer;
        l: Integer;
        errPOS: Integer;
        x: Integer;
        CurrentElement: Text;
        ValuePair: Text;
        txtEWBNum: Text;
        txtStatus: Text;
        CurrentValue: Text;
        txtError: text;
        txtSignedData: text;
        txtInfodDtls: text;
    begin
        //Get value from Json Response >>

        CLEAR(message1);
        CLEAR(CurrentObject);
        p := 0;
        x := 1;

        IF STRPOS(TextResponse, '{}') > 0 THEN
            EXIT;
        //no response

        // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
        // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

        TextResponse := DELCHR(TextResponse, '=', FormatChar);
        l := STRLEN(TextResponse);
        // MESSAGE(TextResponse);
        errPOS := STRPOS(TextResponse, '"Status":0');
        //  recSIHeader.RESET;
        //  recSIHeader.SETFILTER("No.",'=%1',SalesHead."No.");
        //  IF recSIHeader.FINDFIRST THEN BEGIN
        //    recSIHeader."Acknowledgement No." := COPYSTR(TextResponse,1,250);
        //   recSIHeader.MODIFY;
        IF errPOS > 0 THEN
            if not ISIrnCancel then
                ERROR('Error in IRN generation : %1', TextResponse)
            else
                ERROR('Error in IRN cancellation : %1', TextResponse);

        WHILE p < l DO BEGIN
            ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
            IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
                p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
                CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
                CurrentElement := DELCHR(CurrentElement, '=', ':');
                CurrentElement := DELCHR(CurrentElement, '=', '"');


                CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
                CurrentValue := DELCHR(CurrentValue, '=', ':');
                CurrentValue := DELCHR(CurrentValue, '=', '"');

                CASE CurrentElement OF
                    'Status':
                        BEGIN
                            txtStatus := CurrentValue;
                        END;
                    'ErrorDetails':
                        BEGIN
                            txtError := CurrentValue;
                        END;
                    'Data':
                        BEGIN
                            txtSignedData := CurrentValue;
                        END;
                    'InfoDtls':
                        BEGIN
                            txtInfodDtls := CurrentValue;
                        END;
                END;
            END;
            x := x + 1;
        END;

        EXIT(txtSignedData);

    end;

    procedure ParseResponse_IRN_DECRYPT(TextResponse: text; IsIrnCancel: Boolean; SalesCrMemo: Record "Sales Cr.Memo Header"): Text;
    var
        message1: Text;
        CurrentObject: Text;
        FormatChar: label '{}';
        p: Integer;
        l: Integer;
        x: Integer;
        CurrentElement: Text;
        ValuePair: Text;
        txtEWBNum: Text;
        CurrentValue: Text;
        txtCancelDate: text;
        txtAckNum: Text;
        txtIRN: Text;
        txtAckDate: Text;
        txtSignedInvoice: Text;
        txtSignedQR: Text;
        txtEWBDt: text;
        txtEWBValid: Text;
        recSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        txtRemarks: Text;
    begin
        //Get value from Json Response >>

        CLEAR(message1);
        // message(TextResponse);
        CLEAR(CurrentObject);
        p := 0;
        x := 1;

        IF STRPOS(TextResponse, '{}') > 0 THEN
            EXIT;
        //no response

        // CurrentObject := COPYSTR(TextResponse,STRPOS(TextResponse,'{')+1,STRPOS(TextResponse,':'));
        // TextResponse := COPYSTR(TextResponse,STRLEN(CurrentObject)+1);

        TextResponse := DELCHR(TextResponse, '=', FormatChar);
        l := STRLEN(TextResponse);

        WHILE p < l DO BEGIN
            ValuePair := SELECTSTR(x, TextResponse);  // get comma separated pairs of values and element names
            IF STRPOS(ValuePair, ':') > 0 THEN BEGIN
                p := STRPOS(TextResponse, ValuePair) + STRLEN(ValuePair); // move pointer to the end of the current pair in Value
                CurrentElement := COPYSTR(ValuePair, 1, STRPOS(ValuePair, ':'));
                CurrentElement := DELCHR(CurrentElement, '=', ':');
                CurrentElement := DELCHR(CurrentElement, '=', '"');

                CurrentValue := COPYSTR(ValuePair, STRPOS(ValuePair, ':'));
                CurrentValue := DELCHR(CurrentValue, '=', ':');
                CurrentValue := DELCHR(CurrentValue, '=', '"');

                CASE CurrentElement OF
                    'AckNo':
                        BEGIN
                            txtAckNum := CurrentValue;
                        END;
                    'AckDt':
                        BEGIN
                            txtAckDate := CurrentValue;
                        END;
                    'Irn':
                        BEGIN
                            txtIRN := CurrentValue;
                        END;
                    'SignedInvoice':
                        BEGIN
                            txtSignedInvoice := CurrentValue;
                        END;
                    'SignedQRCode':
                        BEGIN
                            txtSignedQR := CurrentValue;
                        END;
                    'EwbNo':
                        BEGIN
                            txtEWBNum := CurrentValue;
                        END;
                    'EwbDt':
                        BEGIN
                            txtEWBDt := CurrentValue;
                        END;
                    'EwbValidTill':
                        BEGIN
                            txtEWBValid := CurrentValue;
                        END;
                    'Remarks':
                        BEGIN
                            txtRemarks := CurrentValue;
                        END;
                    'CancelDate':
                        begin
                            txtCancelDate := CurrentValue;
                        end;
                END;
            END;
            x := x + 1;
        END;


        recSalesCrMemoHeader.RESET;
        recSalesCrMemoHeader.SETFILTER("No.", '=%1', SalesCrMemo."No.");
        IF recSalesCrMemoHeader.FINDFIRST THEN BEGIN
            if not IsIrnCancel then
                UpdateHeaderIRN(txtSignedQR, txtIRN, txtAckDate, txtAckNum, SalesCrMemo)//23102020
            else
                UpdateCancelSalesCrIRN(txtIRN, txtCancelDate, SalesCrMemo);
        END;

        EXIT(txtIRN);

    end;

    procedure UpdateHeaderIRN(QRCodeInput: Text; IRNTxt: Text; AckDt: text; AckNum: Text; SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        FieldRef1: FieldRef;
        QRCodeFileName: Text;
        // TempBlob1: Record TempBlob;
        RecRef1: RecordRef;
        QRGenerator: Codeunit "QR Generator";
        CU_SalesInvoice: Codeunit E_Invoice_SalesInvoice;
        dtText: text;
        blobCU: Codeunit "Temp Blob";
        acknwoledgeDate: DateTime;
        IBarCodeProvider: DotNet BarcodeProvider;
        FileManagement: Codeunit "File Management";
    begin

        // GetBarCodeProvider(IBarCodeProvider);
        // QRCodeFileName := IBarCodeProvider.GetBarcode(QRCodeInput);
        // QRCodeFileName := MoveToMagicPath(QRCodeFileName);

        // Load the image from file into the BLOB field.
        // CLEAR(TempBlob1);
        // TempBlob1.CALCFIELDS(Blob);
        // FileManagement.BLOBImport(TempBlob1, QRCodeFileName);

        //GET SI HEADER REC AND SAVE QR INTO BLOB FIELD


        RecRef1.OPEN(114);
        FieldRef1 := RecRef1.FIELD(3);
        FieldRef1.SETRANGE(SalesCrMemo."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN
            // RecRef1.FieldIndex()
            // FieldRef1 := RecRef1.FIELD(18173);//QR
            // FieldRef1.VALUE := TempBlob1.Blob;
            QRGenerator.GenerateQRCodeImage(QRCodeInput, blobCU);
            // FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("QR Code"));//QR
            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("E-Invoice QR Code"));//QR
            blobCU.ToRecordRef(RecRef1, SalesCrMemo.FieldNo("E-Invoice QR Code"));


            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("IRN Hash"));//IRN Num
            FieldRef1.VALUE := IRNTxt;
            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("Acknowledgement No."));//AckNum
            FieldRef1.VALUE := ACkNum;
            dtText := CU_SalesInvoice.ConvertAckDt(AckDt);
            EVALUATE(acknwoledgeDate, dtText);
            FieldRef1 := RecRef1.FIELD(SalesCrMemo.FieldNo("Acknowledgement Date"));//AckDate
            FieldRef1.VALUE := acknwoledgeDate;
            RecRef1.MODIFY;
        END;
        // Erase the temporary file.
        // IF NOT ISSERVICETIER THEN
        //     IF EXISTS(QRCodeFileName) THEN
        //         ERASE(QRCodeFileName);

    end;

    procedure GetBarCodeProvider(var IBarCodeProvider: DotNet BarcodeProvider)
    var
        QRCodeProvider: DotNet QRProvider;
    begin
        CLEAR(QRCodeProvider);
        QRCodeProvider := QRCodeProvider.QRCodeProvider;
        IBarCodeProvider := QRCodeProvider;
    end;

    procedure CancelSalesCrMemo_IRN(recSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        JsonObj1: DotNet JObject;
        JsonWriter1: DotNet JsonTextWriter;
        jsonString: text;
        jsonObjectlinq: DotNet JObject;
        GSTInv_DLL: DotNet GSTEncr_Decr1;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        encryptedIRNPayload: text;
        txtDecryptedSek: text;
        finalPayload: text;
        jsonWriter2: DotNet JsonTextWriter;
        codeReason: Code[2];
        intReasonCOde: Integer;
        CUSalesCRMemoInvoice: Codeunit GST_Einvoice_CrMemo;

    begin
        JsonObj1 := JsonObj1.JObject();
        JsonWriter1 := JsonObj1.CreateWriter();

        JsonWriter1.WritePropertyName('Irn');
        JsonWriter1.WriteValue(recSalesCrMemoHeader."IRN Hash");

        JsonWriter1.WritePropertyName('CnlRsn');
        Case recSalesCrMemoHeader."Cancel Reason" of
            recSalesCrMemoHeader."Cancel Reason"::Duplicate:
                codeReason := '1';
            recSalesCrMemoHeader."Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recSalesCrMemoHeader."Cancel Reason"::"Order Canceled":
                codeReason := '3';
            recSalesCrMemoHeader."Cancel Reason"::Other:
                codeReason := '4';
        end;
        // codeReason:
        JsonWriter1.WriteValue(codeReason);

        JsonWriter1.WritePropertyName('CnlRem');
        JsonWriter1.WriteValue(recSalesCrMemoHeader."E-Invoice Cancel Remarks");

        jsonString := JsonObj1.ToString();

        GenerateAuthToken(recSalesCrMemoHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, recSalesCrMemoHeader."No.");
        if recAuthData.Findlast() then begin

            txtDecryptedSek := recAuthData.DecryptedSEK;

            Message(jsonString);

            GSTInv_DLL := GSTInv_DLL.RSA_AES();
            // base64IRN := CU_Base64.ToBase64(JsonText);
            encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(jsonString, txtDecryptedSek);

            jsonObjectlinq := jsonObjectlinq.JObject();
            jsonWriter2 := jsonObjectlinq.CreateWriter();

            jsonWriter2.WritePropertyName('Data');
            jsonWriter2.WriteValue(encryptedIRNPayload);



            finalPayload := jsonObjectlinq.ToString();
            // Message('FinalIRNPayload %1 ', finalPayload);
            Call_IRN_API(recAuthData, finalPayload, true, recSalesCrMemoHeader);
        end;

    end;

    procedure UpdateCancelSalesCrIRN(txtIRN: Text; CancelDate: Text; recSalesCrHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrHeader: Record "Sales Cr.Memo Header";
        txtCancelDate: text;
        CUSalesInvoice: Codeunit E_Invoice_SalesInvoice;
    begin
        SalesCrHeader.get(recSalesCrHeader."No.");
        SalesCrHeader."IRN Hash" := txtIRN;
        txtCancelDate := CUSalesInvoice.ConvertAckDt(CancelDate);
        evaluate(SalesCrHeader."E-Inv. Cancelled Date", txtCancelDate);
        SalesCrHeader.Modify();

    end;


    procedure MoveToMagicPath(SourceFileName: text): text;
    var
        DestinationFileName: Text;
        FileManagement: Codeunit "File Management";
        FileSystemObject: Text;
    begin


        // User Temp Path
        // DestinationFileName := COPYSTR(FileManagement.ClientTempFileName(''), 1, 1024);
        // // IF ISCLEAR(FileSystemObject) THEN
        // //   CREATE(FileSystemObject,TRUE,TRUE);
        // FileManagement.MoveFile(SourceFileName, DestinationFileName);
    end;


}
