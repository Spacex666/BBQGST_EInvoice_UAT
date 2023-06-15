//Creating New Codeunit for E-Invoice and E-Way bill  **CITS_RS

dotnet
{
    assembly(Microsoft.Dynamics.Nav.MX)
    {
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.IBarcodeProvider; BarcodeProvider) { }
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.QRCodeProvider; QRProvider) { }
    }
    assembly(GST_Invoice_Encrypt)
    {
        type(GST_Invoice_Encrypt.RSA_AES; GSTEncr_Decr) { }
    }
    assembly(GST_Invoice_Encrypt)
    {
        type(GST_Invoice_Encrypt.RSA_AES; GSTEncr_Decr1) { }
    }
    assembly(ClassLibrary1)
    {
        type(ConsoleApp1.EncryptUserCreds; GST_Bouncy) { }
    }

    assembly(GST_Invoice103)
    {
        type(GST_Invoice103.EInvoice; GST103) { }
    }


}

codeunit 50148 E_Invoice_SalesInvoice
{
    trigger OnRun()
    begin

    end;

    procedure GenerateIRN_01(SalesHead: Record "Sales Invoice Header")
    var
        txtDecryptedSek: text;
        GSTInv_DLL: DotNet GSTEncr_Decr1;
        recAuthData: Record "GST E-Invoice(Auth Data)";
        jsonwriter1: DotNet JsonTextWriter;
        jsonObjectlinq: DotNet JObject;
        eInvoiceJsonHandler: Codeunit "e-Invoice Json Handler";
        encryptedIRNPayload: text;
        finalPayload: text;
        JObject: JsonObject;
        GSTManagement: Codeunit "e-Invoice Management";
        CU_Base64: Codeunit "Base64 Convert";
        base64IRN: text;
        CurrExRate: Integer;
        AesManaged: DotNet "Cryptography.SymmetricAlgorithm";
        // GSTBouncyDLL: DotNet GST_Bouncy;
        // GST103: DotNet GST103;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        clear(GlobalNULL);
        // IsInvoice := true;
        // JObject.WriteTo(JsonText);
        // Message(JsonText);
        // message(format(SalesHead.FieldNo("Acknowledgement Date")));
        // message(format(SalesHead.FieldNo("Acknowledgement No.")));
        // message(format(SalesHead.FieldNo("QR Code")));
        // message(format(SalesHead.FieldNo("IRN Hash")));
        JsonLObj := JsonLObj.JObject();
        JsonWriter := JsonLObj.CreateWriter;
        DocumentNo := SalesHead."No.";
        // IF SalesHead.FIND('-') THEN
        IF GSTManagement.IsGSTApplicable(SalesHead."No.", 36) THEN BEGIN
            IF SalesHead."GST Customer Type" IN
                [SalesHead."GST Customer Type"::Unregistered,
                SalesHead."GST Customer Type"::" "] THEN
                ERROR('E-Invoicing is not applicable for Unregistered, Export and Deemed Export Customers.');

        end;
        IF SalesHead."Currency Factor" <> 0 THEN
            CurrExRate := 1 / SalesHead."Currency Factor"
        ELSE
            CurrExRate := 1;
        JsonWriter.WritePropertyName('Version');//NIC API Version
        JsonWriter.WriteValue('1.1');//Later to be provided as setup.

        WriteTransDtls(JsonLObj, SalesHead, JsonWriter);
        WriteDocDtls(JsonLObj, SalesHead, JsonWriter);
        WriteSellerDtls(JsonLObj, SalesHead, JsonWriter);
        WriteBuyerDtls(JsonLObj, SalesHead, JsonWriter, gl_BillToPh, gl_BillToEm);
        WriteItemDtls(JsonLObj, SalesHead, JsonWriter, CurrExRate);
        WriteValDtls(JsonLObj, SalesHead, JsonWriter);
        WriteExpDtls(JsonLObj, SalesHead, JsonWriter);


        JsonText := JsonLObj.ToString();

        GenerateAuthToken(SalesHead);//Auth Token ans Sek stored in Auth Table
                                     //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)
        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, SalesHead."No.");
        if recAuthData.Findlast() then begin
            // Message('DecryptedSEK %1', recAuthData.DecryptedSEK);
            txtDecryptedSek := recAuthData.DecryptedSEK;

            Message(JsonText);

            GSTInv_DLL := GSTInv_DLL.RSA_AES();
            // GSTBouncyDLL := GSTBouncyDLL.EncryptUserCreds();
            // GST103 := GST103.EInvoice();


            // base64IRN := CU_Base64.ToBase64(JsonText);
            encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);
            // encryptedIRNPayload := GSTBouncyDLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);
            // encryptedIRNPayload := GST103.EncryptBySymmetricKey(JsonText, txtDecryptedSek);
            // base64IRN := CU_Base64.ToBase64(JsonText);
            // base64IRN := CU_Base64.ToBase64(encryptedIRNPayload);
            // encryptedIRNPayload := GSTInv_DLL.EncryptBySymmetricKey(JsonText, txtDecryptedSek);
            // Message('EncryptedIRNPayload %1', encryptedIRNPayload);


            // Message('Base64EncryptedIRNPayload %1', base64IRN);

            jsonObjectlinq := jsonObjectlinq.JObject();
            jsonwriter1 := jsonObjectlinq.CreateWriter();

            jsonwriter1.WritePropertyName('Data');
            jsonwriter1.WriteValue(encryptedIRNPayload);
            // jsonwriter1.WriteValue(base64IRN);


            finalPayload := jsonObjectlinq.ToString();
            // Message('FinalIRNPayload %1 ', finalPayload);
            Call_IRN_API(recAuthData, finalPayload, false, SalesHead, false, false);
        end;
        if DocumentNo = '' then
            //     Message(JsonText)
            // else
            Error(DocumentNoBlankErr);

    end;

    procedure GenerateAuthToken(RecSalesHeader: Record "Sales Invoice Header"): text;
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
        recLocation.Get(RecSalesHeader."Location Code");
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
        getAuthfromNIC(finPayload, plainAppkey, RecSalesHeader);
        // Message(finPayload);
        exit(finPayload);
        // exit(jsonString);
    end;

    procedure getAuthfromNIC(JsonString: text; PlainKey: Text; SalesHeader: Record "Sales Invoice Header")
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
        recLocation.Get(SalesHeader."Location Code");
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
            //    encryptedSEK := ParseResponse_Auth(glreader.ReadToEnd,appKey,SIHeader);
            // Myfile.OPEN(genledSetup."GST Public Key Directory Path");
            // Myfile.CREATEINSTREAM(Instream);
            // Instream.READTEXT(keyTxt);
            responsetxt := glReader.ReadToEnd();
            // Message(responsetxt);
            ParseAuthResponse(responsetxt, PlainKey, SalesHeader);


            // Encoding := Encoding.UTF8Encoding();
            // Bytes := Encoding.GetBytes(appKey);

            // BouncyThat1 := BouncyThat1.Class1();
            // decyptSEK := BouncyThat1.DecryptBySymmetricKey(encryptedSEK,Bytes);

            // GSTEnc_Decr := GSTEnc_Decr.RSA_AES();
            // decyptSEK   := GSTEnc_Decr.DecryptBySymmetricKey(encryptedSEK,Bytes);

            /*recAuthData.RESET;
            recAuthData.SETCURRENTKEY("Sr No.");
            recAuthData.SETFILTER(DocumentNum,'=%1',SIHeader."No.");
            IF recAuthData.FINDLAST THEN BEGIN
             recAuthData.DecryptedSEK := decyptSEK;
             recAuthData.MODIFY;
            END;

           glreader.Close();
           glreader.Dispose();

          END ELSE
           IF glResponse.StatusCode <> 200 THEN BEGIN
            MESSAGE(FORMAT(glResponse.StatusCode));
            ERROR(glResponse.StatusDescription);
           END;*/
        END;
    END;

    procedure ParseAuthResponse(TextResponse: text; PlainKey: text; SIHeader: Record "Sales Invoice Header"): text;
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
        recAuthData.DocumentNum := SIHeader."No.";
        recAuthData.INSERT;

        recAuthData.Reset();
        recAuthData.SetRange(DocumentNum, SIHeader."No.");
        if recAuthData.Findlast() then begin
            GSTIn_DLL := GSTIn_DLL.RSA_AES();
            bytearr := encoding.UTF8.GetBytes(recAuthData.PlainAppKey);
            PlainSEK := GSTIn_DLL.DecryptBySymmetricKey(recAuthData.SEK, bytearr);
            // message('SEK 1 %1,', PlainSEK);
            recAuthData.DecryptedSEK := PlainSEK;
            recAuthData.Modify();
        end;

        EXIT(txtEncSEK);
    end;

    procedure Call_IRN_API(recAuthData: Record "GST E-Invoice(Auth Data)"; JsonString: text; IsIRNCancel: Boolean; SalesHead: record "Sales Invoice Header"; IsEWayBill: Boolean; IsEWayCancel: Boolean)
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
        recLocation.get(SalesHead."Location Code");
        recGSTRegNos.Reset();
        recGSTRegNos.SetRange(Code, recLocation."GST Registration No.");
        if recGSTRegNos.FindFirst() then;
        CLEAR(glHTTPRequest);
        servicepointmanager.SecurityProtocol := securityprotocol.Tls12;
        if IsEWayBill then
            gluriObj := gluriObj.Uri(genledSetup."E_Way Bill URL")
        else
            if IsIRNCancel then
                gluriObj := gluriObj.Uri(genledSetup."Cancel E-Invoice URL")
            else
                if IsEWayCancel then
                    gluriObj := gluriObj.Uri(genledSetup."Cancel E-Way Bill")
                else
                    gluriObj := gluriObj.Uri(genledSetup."GST IRN Generation URL");



        // gluriObj := gluriObj.Uri('https://einv-apisandbox.nic.in/eicore/v1.03/Invoice');
        glHTTPRequest := glHTTPRequest.CreateDefault(gluriObj);
        // glHTTPRequest.Headers.Add('client_id', recGSTRegNos."E-Invoice Client ID");
        // glHTTPRequest.Headers.Add('client_secret', recGSTRegNos."E-Invoice Client Secret");
        // glHTTPRequest.Headers.Add('gstin', recGSTRegNos.Code);
        // glHTTPRequest.Headers.Add('user_name', recGSTRegNos."E-Invoice UserName");
        glHTTPRequest.Headers.Add('gstin', GSTIN);
        glHTTPRequest.Headers.Add('client_id', clientID);
        glHTTPRequest.Headers.Add('client_secret', clientSecret);
        if not IsEWayCancel then
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
            signedData := ParseResponse_IRN_ENCRYPT(glreader.ReadToEnd, IsEWayBill, IsEWayCancel, IsIRNCancel);

            GSTEncrypt := GSTEncrypt.RSA_AES();
            decryptedIRNResponse := GSTEncrypt.DecryptBySymmetricKey(signedData, recAuthData.DecryptedSEK);

            /*path := 'E:\GST_invoice\file_'+DELCHR(FORMAT(TODAY),'=',char)+'_'+DELCHR(FORMAT(TIME),'=',char)+'.txt';//+FORMAT(TODAY)+FORMAT(TIME)+'.txt';
            File.CREATE(path);
            File.CREATEOUTSTREAM(Outstr);
            Outstr.WRITETEXT(decryptedIRNResponse);*/
            ParseResponse_IRN_DECRYPT(decryptedIRNResponse, IsEWayBill, IsEWayCancel, IsIRNCancel, SalesHead);

            glreader.Close();
            glreader.Dispose();
        END
        ELSE
            IF (glResponse.StatusCode <> 200) THEN BEGIN
                MESSAGE(FORMAT(glResponse.StatusCode));
                ERROR(glResponse.StatusDescription);
            END;

    end;

    procedure ParseResponse_IRN_ENCRYPT(TextResponse: text; IsEwayBill: boolean; IsEwayCancel: Boolean; ISIRNCancel: Boolean): Text;
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
        if errPOS = 0 then
            errPOS := StrPos(TextResponse, '"status":"0"');
        if errPOS = 0 then
            errPOS := StrPos(TextResponse, '"Status":"0"');
        //  recSIHeader.RESET;
        //  recSIHeader.SETFILTER("No.",'=%1',SalesHead."No.");
        //  IF recSIHeader.FINDFIRST THEN BEGIN
        //    recSIHeader."Acknowledgement No." := COPYSTR(TextResponse,1,250);
        //   recSIHeader.MODIFY;
        IF errPOS > 0 THEN
            if IsEwayBill then
                ERROR('Error in E-Way Bill generation : %1', TextResponse)
            else
                if IsEwayCancel then
                    ERROR('Error in E-Way Bill cancellation : %1', TextResponse)
                else
                    if ISIRNCancel then
                        ERROR('Error in IRN cancellation : %1', TextResponse)
                    else
                        ERROR('Error in IRN generation : %1', TextResponse);



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
                    'status':    //for E-way cancel and E-Invoice cancel
                        txtStatus := CurrentValue;
                    'ErrorDetails':
                        BEGIN
                            txtError := CurrentValue;
                        END;
                    'Data':
                        BEGIN
                            txtSignedData := CurrentValue;
                        END;
                    'data':        //for E-way cancel and E-Invoice cancel
                        txtSignedData := CurrentValue;
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

    procedure ParseResponse_IRN_DECRYPT(TextResponse: text; IsEWayBill: Boolean; IsEwayCancel: Boolean; ISIRNCancel: Boolean; SalesHead: Record "Sales Invoice Header"): Text;
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
        txtAckNum: Text;
        txtIRN: Text;
        txtAckDate: Text;
        txtSignedInvoice: Text;
        txtCancelIRNDate: text;
        txtSignedQR: Text;
        txtEWBDt: text;
        recSIHead: Record "Sales Invoice Header";
        txtEWBValid: Text;
        txtRemarks: Text;
        txtCancelEwayNum: Text;
        txtCancelEWayDt: text;
        CU_EWaybill: Codeunit Generate_EWayBill_SalesInvoice;
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
                            txtCancelIRNDate := CurrentValue;
                        end;
                    'ewayBillNo':
                        begin
                            txtCancelEwayNum := CurrentValue;
                        end;
                    'cancelDate':
                        begin
                            txtCancelEWayDt := CurrentValue;
                        end;

                END;
            END;
            x := x + 1;
        END;


        recSIHead.RESET;
        recSIHead.SETFILTER("No.", '=%1', SalesHead."No.");
        IF recSIHead.FINDFIRST THEN BEGIN
            if IsEWayBill then
                CU_EWaybill.UpdateHeaderIRN(txtEWBDt, txtEWBNum, txtEWBValid, SalesHead)//230622
            else
                if ISIRNCancel then
                    UpdateCancelDetails(txtIRN, txtCancelIRNDate, SalesHead)//150722
                else
                    if IsEwayCancel then
                        CU_EWaybill.UpdateEWayCancelHeader(txtCancelEwayNum, txtCancelEWayDt, SalesHead)//160722
                    else
                        UpdateHeaderIRN(txtSignedQR, txtIRN, txtAckDate, txtAckNum, SalesHead);//23102020


        END;

        EXIT(txtIRN);

    end;


    procedure updateHeader()
    var
        cu_jsonhandler: Codeunit "e-Invoice Json Handler";
    begin
        //  cu_jsonhandler.GetEInvoiceResponse();

    end;

    procedure UpdateHeaderIRN(QRCodeInput: Text; IRNTxt: Text; AckDt: text; AckNum: Text; SalesHead: Record "Sales Invoice Header")
    var
        FieldRef1: FieldRef;
        QRCodeFileName: Text;
        // TempBlob1: Record TempBlob;
        QRGenerator: Codeunit "QR Generator";
        RecRef1: RecordRef;
        dtText: text;
        inStr: InStream;
        acknwoledgeDate: DateTime;
        cu_jsonhandler: Codeunit "e-Invoice Json Handler";
        IBarCodeProvider: DotNet BarcodeProvider;
        blobCU: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin

        // GetBarCodeProvider(IBarCodeProvider);
        // QRCodeFileName := IBarCodeProvider.GetBarcode(QRCodeInput);
        // QRCodeFileName := MoveToMagicPath(QRCodeFileName);

        // Load the image from file into the BLOB field.
        // CLEAR(TempBlob1);
        // Clear((blobCU));
        // blobCU.CreateInStream(inStr);
        // TempBlob1.CALCFIELDS(Blob);
        // blobCU.
        // FileManagement.BLOBImport(blobCU, QRCodeFileName);

        //GET SI HEADER REC AND SAVE QR INTO BLOB FIELD
        RecRef1.OPEN(112);
        FieldRef1 := RecRef1.FIELD(3);
        FieldRef1.SETRANGE(SalesHead."No.");//Parameter
        IF RecRef1.FINDFIRST THEN BEGIN
            // cu_jsonhandler.GetEInvoiceResponse(RecRef1);

            // QRGenerator.GenerateQRCodeImage(QRCodeInput, blobCU);
            // FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("QR Code"));

            // FieldRef1 := RecRef1.FIELD(18173);//QR
            QRGenerator.GenerateQRCodeImage(QRCodeInput, blobCU);
            // FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("QR Code"));//QR
            FieldRef1 := RecRef1.FIELD(SalesHead.FieldNo("E-Invoice QR Code"));//QR
            blobCU.ToRecordRef(RecRef1, SalesHead.FieldNo("E-Invoice QR Code"));
            // blobCU.ToRecordRef(RecRef1, 18173);
            // FieldRef1.VALUE := blobCU;// TempBlob1.Blob;
            // FieldRef1 := RecRef1.FIELD(18172);//IRN Num
            FieldRef1 := RecRef1.Field(SalesHead.FieldNo("IRN Hash"));
            FieldRef1.VALUE := IRNTxt;
            // FieldRef1 := RecRef1.FIELD(18171);//AckNum
            FieldRef1 := RecRef1.Field(SalesHead.FieldNo("Acknowledgement No."));
            FieldRef1.VALUE := ACkNum;
            // FieldRef1 := RecRef1.FIELD(18174);//AckDate
            dtText := ConvertAckDt(AckDt);
            FieldRef1 := RecRef1.Field(SalesHead.FieldNo("Acknowledgement Date"));
            EVALUATE(acknwoledgeDate, dtText);
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

    procedure ConvertAckDt(DtText: text): text;
    var
        DateTime_Fin: text;
        YYYY: text;
        DD: text;
        MM: text;
    begin
        YYYY := COPYSTR(DtText, 1, 4);
        MM := COPYSTR(DtText, 6, 2);
        DD := COPYSTR(DtText, 9, 2); // CCIT AN  Generate Wrong EWAYbill Date


        //erroneous code CITS_RS commented 140623
        // DD := CopyStr(DtText, 1, 2);
        // MM := CopyStr(DtText, 4, 2);
        // YYYY := CopyStr(DtText, 7, 4);//New Added CCIT AN 13062023

        // TIME := COPYSTR(AckDt2,12,8);

        DateTime_Fin := DD + '/' + MM + '/' + YYYY + ' ' + COPYSTR(DtText, 12, 8);
        // DateTime_Fin := MM + '/' + DD + '/' + YYYY + ' ' + COPYSTR(DtText, 12, 8);
        exit(DateTime_Fin);
    end;



    procedure WriteTransDtls(VAR JsonObj: DotNet JObject; SalesInHeader: Record "Sales Invoice Header"; VAR JsonWriter: DotNet JsonTextWriter)
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


        IF (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::Registered)
        OR (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::Exempted) THEN BEGIN
            category := 'B2B';

        END ELSE
            IF
   (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::Export) THEN BEGIN
                IF SalesInHeader."GST Without Payment of Duty" THEN
                    category := 'EXPWOP'
                ELSE
                    category := 'EXPWP'
            END ELSE
                IF
           (SalesInHeader."GST Customer Type" = SalesInHeader."GST Customer Type"::"Deemed Export") THEN
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

    procedure WriteDocDtls(VAR JsonObj: DotNet JObject; SalesInHeader: Record "Sales Invoice Header"; VAR JsonWriter: DotNet JsonTextWriter)
    var
        txtDocDate: Text[20];
        Typ: Code[20];
    begin
        IF SalesInHeader."Invoice Type" = SalesInHeader."Invoice Type"::Taxable THEN
            Typ := 'INV'
        ELSE
            IF (SalesInHeader."Invoice Type" = SalesInHeader."Invoice Type"::"Debit Note") OR
            (SalesInHeader."Invoice Type" = SalesInHeader."Invoice Type"::Supplementary)
            THEN
                Typ := 'DBN'
            ELSE
                Typ := 'INV';
        txtDocDate := FORMAT(SalesInHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');

        //***Doc Details Start
        JsonWriter.WritePropertyName('DocDtls');
        JsonWriter.WriteStartObject();

        //DocType
        JsonWriter.WritePropertyName('Typ');
        JsonWriter.WriteValue(Typ);

        //Doc Num
        JsonWriter.WritePropertyName('No');
        JsonWriter.WriteValue(COPYSTR(SalesInHeader."No.", 1, 16));

        /*dtDay := FORMAT(DATE2DMY(TODAY,1));
        dtMonth := FORMAT(DATE2DMY(TODAY,2));
        dtYear := FORMAT(DATE2DMY(TODAY,3));
        txtDocDate := dtDay+'/'+dtMonth+'/'+dtYear;
        MESSAGE(txtDocDate);*/
        JsonWriter.WritePropertyName('Dt');
        JsonWriter.WriteValue(txtDocDate);

        JsonWriter.WriteEndObject();
        //***Doc Details End--


    end;

    procedure WriteSellerDtls(VAR JsonObj: DotNet JObject; SalesInHeader: Record "Sales Invoice Header"; VAR JsonWriter: DotNet JsonTextWriter)
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
        WITH SalesInHeader DO BEGIN
            Location.GET(SalesInHeader."Location Code");
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

    procedure WriteBuyerDtls(VAR JsonObj: DotNet JObject; SalesInvoiceHeader: Record "Sales Invoice Header"; VAR JsonWriter: DotNet JsonTextWriter; BilltoPh: Code[20]; BillToEm: Text[100])
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
        SalesInvoiceLine: Record "Sales Invoice Line";
        StateBuff: Record State;
        Contact: Record Contact;
        recCustomer: Record Customer;
    begin



        WITH SalesInvoiceHeader DO BEGIN
            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                Gstin := 'URP'
            ELSE BEGIN
                customerrec.GET(SalesInvoiceHeader."Sell-to Customer No.");
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

            SalesInvoiceLine.SETRANGE("Document No.", "No.");
            SalesInvoiceLine.SETFILTER("GST Place of Supply", '<>%1', SalesInvoiceLine."GST Place of Supply"::" ");
            IF SalesInvoiceLine.FINDFIRST THEN
                IF SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Bill-to Address" THEN BEGIN
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
                    IF SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" THEN BEGIN
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

    procedure WriteItemDtls(VAR JsonObj: DotNet JObject; VAR SalesInHeader: Record "Sales Invoice Header"; VAR JsonWriter: DotNet JsonTextWriter; CurrExchRt: Decimal)
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
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        CLEAR(SlNo);
        SalesInvoiceLine.SETRANGE("Document No.", SalesInHeader."No.");
        //  SalesInvoiceLine.SETRANGE("Non-GST Line",FALSE);
        SalesInvoiceLine.SETFILTER(Type, '<>%1', SalesInvoiceLine.Type::" ");
        IF SalesInvoiceLine.FINDSET THEN BEGIN
            IF SalesInvoiceLine.COUNT > 100 THEN
                ERROR(SalesLineErr, SalesInvoiceLine.COUNT);
            JsonWriter.WritePropertyName('ItemList');
            JsonWriter.WriteStartArray;
            REPEAT
                SlNo += 1;
                //   {IF SalesInvoiceLine."GST On Assessable Value" THEN
                //     AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
                //   ELSE}
                if SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 then
                    AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
                else
                    AssAmt := SalesInvoiceLine.Amount;



                // AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)";

                //   IF SalesInvoiceLine."Free Supply" THEN
                //     FreeQty := SalesInvoiceLine.Quantity
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
                    SalesInvoiceLine."Document No.",
                    SalesInvoiceLine."Line No.",
                    CGSTRate,
                    SGSTRate,
                    IGSTRate,
                    CessRate,
                    CesNonAdval,
                    StateCess, GSTRt
                );
                CLEAR(UOM);
                IF SalesInvoiceLine."Unit of Measure Code" <> '' THEN
                    UOM := COPYSTR(SalesInvoiceLine."Unit of Measure Code", 1, 8)
                ELSE
                    UOM := OTHTxt;
                IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Service THEN
                    IsServc := 'Y'
                ELSE
                    IsServc := 'N';
                /*WriteItem(
                  SalesInvoiceLine.Description + SalesInvoiceLine."Description 2",
                  SalesInvoiceLine."HSN/SAC Code",
                  SalesInvoiceLine.Quantity,
                  FreeQty,
                  UOM,
                  SalesInvoiceLine."Unit Price",
                  SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                  SalesInvoiceLine."Line Discount Amount",
                  SalesInvoiceLine."Line Amount",
                  AssAmt,
                  CGSTRate,
                  IGSTRate,
                  IgstAmt,
                  StateCesRt,
                  CesAmt,
                  CesNonAdval,
                  StateCesRt,
                  StateCesAmt,
                  StateCesNonAdvlAmt,
                  0,
                  SalesInvoiceLine."Amount Including Tax" + SalesInvoiceLine."Total GST Amount",
                  SalesInvoiceLine."Line No.",
                  SlNo,
                  IsServc, JsonWriter, CurrExchRt, GSTRt);*/

                GetGSTValueForLine(SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.", CGSTValue, SGSTValue, IGSTValue);

                WriteItem(
                        SalesInvoiceLine.Description + SalesInvoiceLine."Description 2", '',
                        SalesInvoiceLine."HSN/SAC Code", '',
                        SalesInvoiceLine.Quantity, FreeQty,
                        CopyStr(SalesInvoiceLine."Unit of Measure Code", 1, 3),
                        SalesInvoiceLine."Unit Price",
                        SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount",
                        SalesInvoiceLine."Line Discount Amount", 0,
                        AssAmt, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess,
                        (AssAmt + CGSTValue + SGSTValue + IGSTValue),
                        SlNo,
                        IsServc,
                        CurrExchRt,
                        GSTRt, CGSTValue, SGSTValue, IGSTValue);

            UNTIL SalesInvoiceLine.NEXT = 0;
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

        /*IF IsInvoice THEN
        InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Invoice Line",0,DocumentNo,'',0,SILineNo)
        ELSE
        InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Cr.Memo Line",0,DocumentNo,'',0,SILineNo);
        ValueEntryRelation.SETCURRENTKEY("Source RowId");
        ValueEntryRelation.SETRANGE("Source RowId",InvoiceRowID);
        IF ValueEntryRelation.FINDSET THEN BEGIN
        xLotNo := '';
        JsonTextWriter.WritePropertyName('BchDtls');
        JsonTextWriter.WriteStartObject;
        REPEAT
            ValueEntry.GET(ValueEntryRelation."Value Entry No.");
            ItemLedgerEntry.SETCURRENTKEY("Item No.",Open,"Variant Code",Positive,"Lot No.","Serial No.");
            ItemLedgerEntry.GET(ValueEntry."Item Ledger Entry No.");
            IF xLotNo <> ItemLedgerEntry."Lot No." THEN BEGIN
            WriteBchDtls(
                COPYSTR(ItemLedgerEntry."Lot No.",1,20),
                FORMAT(ItemLedgerEntry."Expiration Date",0,'<Day,2>/<Month,2>/<Year4>'),
                FORMAT(ItemLedgerEntry."Warranty Date",0,'<Day,2>/<Month,2>/<Year4>'));
            xLotNo := ItemLedgerEntry."Lot No.";
            END;
        UNTIL ValueEntryRelation.NEXT = 0;
        JsonTextWriter.WriteEndObject;
        END;
        */

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
        JsonWriter.WriteValue(UnitPrice);// * CurrExRate);

        JsonWriter.WritePropertyName('TotAmt');
        JsonWriter.WriteValue(TotAmount);// * CurrExRate);

        JsonWriter.WritePropertyName('Discount');
        JsonWriter.WriteValue(Discount);// * CurrExRate);

        // JsonWriter.WritePropertyName('PreTaxVal');
        // JsonWriter.WriteValue(PreTaxVal * CurrExRate);

        JsonWriter.WritePropertyName('AssAmt');
        JsonWriter.WriteValue(Round(AssessableAmount, 0.01, '='));// * CurrExRate);

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

        /*JsonTextWriter.WritePropertyName('OthChrg');
        JsonTextWriter.WriteValue(OthChrg);

        JsonTextWriter.WritePropertyName('OrdLineRef');
        JsonTextWriter.WriteValue(GlobalNULL);

        JsonTextWriter.WritePropertyName('OrgCntry');
        JsonTextWriter.WriteValue('IN');

        JsonTextWriter.WritePropertyName('PrdSlNo');
        JsonTextWriter.WriteValue(GlobalNULL);*/

        JsonWriter.WriteEndObject;

    end;




    procedure GetGSTComponentRate(
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
            // GSTRate := DetailedGSTLedgerEntry."GST %"
        end else
            CGSTRate := 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then begin
            SGSTRate := DetailedGSTLedgerEntry."GST %";
            GSTRate := 2 * (DetailedGSTLedgerEntry."GST %");
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

    procedure GetGSTValue(
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
       var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TotGSTAmt: Decimal;
    begin
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);

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

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            repeat
                if DetailedGSTLedgerEntry."GST %" > 0 then
                    CessAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
                else
                    CessNonAdvanceAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;


        GSTLedgerEntry.Reset();
        GSTLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        // GSTLedgerEntry.SetFilter("GST Component Code", '<>%1|<>%2|<>%3|<>%4', 'CGST', 'SGST', 'IGST', 'CESS');
        if GSTLedgerEntry.Find('-') then
            repeat
                if (GSTLedgerEntry."GST Component Code") in ['CGST', 'SGST', 'IGST', 'CESS'] then
                    StateCessValue := 0
                else
                    StateCessValue += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0;

        // if IsInvoice then begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        if SalesInvoiceLine.Find('-') then
            repeat
                AssessableAmount += SalesInvoiceLine.Amount;
                DiscountAmount += SalesInvoiceLine."Inv. Discount Amount";
            until SalesInvoiceLine.Next() = 0;
        TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;

        AssessableAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesInvoiceHeader."Currency Code", AssessableAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        TotGSTAmt := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesInvoiceHeader."Currency Code", TotGSTAmt, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        DiscountAmount := Round(
            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
              WorkDate(), SalesInvoiceHeader."Currency Code", DiscountAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
        // end;
        /* else begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
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
                    SalesCrMemoHeader."Currency Code",
                    AssessableAmount,
                    SalesCrMemoHeader."Currency Factor"),
                    0.01,
                    '=');

            TotGSTAmt := Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    TotGSTAmt,
                    SalesCrMemoHeader."Currency Factor"),
                    0.01,
                    '=');

            DiscountAmount := Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    WorkDate(),
                    SalesCrMemoHeader."Currency Code",
                    DiscountAmount,
                    SalesCrMemoHeader."Currency Factor"),
                    0.01,
                    '=');
        end;*/

        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        // if IsInvoice then begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
        end;
        // end;
        /* else begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
            CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        end;*/



        OtherCharges := 0;
    end;

    procedure GetGSTValueForLine(
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
        if DetailedGSTLedgerEntry.Find('-') then
            repeat
                CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.Find('-') then
            repeat
                SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.Find('-') then
            repeat
                IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure WriteValDtls(
        JsonObj1: DotNet JObject;
        SIHeader: Record "Sales Invoice Header";
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
        GetGSTValue(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue, SIHeader);

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
        // JsonWriter.WriteValue(StateCessAmount);
        JsonWriter.WriteValue(0.0);

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

    procedure WriteExpDtls(JsonObj1: DotNet JObject; SalesInvoiceHeader: Record "Sales Invoice Header"; JsonWriter1: DotNet JsonTextWriter)
    var
        ExportCategory: code[20];
        DocumentAmount: Decimal;
        SalesInvoiceLine: Record "Sales Invoice Line";
        WithPayOfDuty: Code[2];
        ShipmentBillNo: Code[20];
        ExitPort: code[10];
        ShipmentBillDate: text;
        CurrencyCode: code[3];
        CountryCode: code[2];
    begin
        if not (SalesInvoiceHeader."GST Customer Type" in [
            SalesInvoiceHeader."GST Customer Type"::Export,
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export",
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit",
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development"])
        then
            exit;

        case SalesInvoiceHeader."GST Customer Type" of
            SalesInvoiceHeader."GST Customer Type"::Export:
                ExportCategory := 'DIR';
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export":
                ExportCategory := 'DEM';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit":
                ExportCategory := 'SEZ';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development":
                ExportCategory := 'SED';
        end;

        if SalesInvoiceHeader."GST Without Payment of Duty" then
            WithPayOfDuty := 'N'
        else
            WithPayOfDuty := 'Y';

        ShipmentBillNo := CopyStr(SalesInvoiceHeader."Bill Of Export No.", 1, 16);
        ShipmentBillDate := Format(SalesInvoiceHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        ExitPort := SalesInvoiceHeader."Exit Point";

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                DocumentAmount := DocumentAmount + SalesInvoiceLine.Amount;
            until SalesInvoiceLine.Next() = 0;

        CurrencyCode := CopyStr(SalesInvoiceHeader."Currency Code", 1, 3);
        CountryCode := CopyStr(SalesInvoiceHeader."Bill-to Country/Region Code", 1, 2);

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

    procedure CancelSalesE_Invoice(recSalesInvoiceHeader: Record "Sales Invoice Header")
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

    begin
        JsonObj1 := JsonObj1.JObject();
        JsonWriter1 := JsonObj1.CreateWriter();

        JsonWriter1.WritePropertyName('Irn');
        JsonWriter1.WriteValue(recSalesInvoiceHeader."IRN Hash");

        JsonWriter1.WritePropertyName('CnlRsn');
        Case recSalesInvoiceHeader."E-Invoice Cancel Reason" of
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::"Duplicate Order":
                codeReason := '1';
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::"Data Entry Mistake":
                codeReason := '2';
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::"Order Cancelled":
                codeReason := '3';
            recSalesInvoiceHeader."E-Invoice Cancel Reason"::Other:
                codeReason := '4';
        end;
        // codeReason:
        JsonWriter1.WriteValue(codeReason);

        JsonWriter1.WritePropertyName('CnlRem');
        JsonWriter1.WriteValue(recSalesInvoiceHeader."E-Invoice Cancel Remarks");

        jsonString := JsonObj1.ToString();

        GenerateAuthToken(recSalesInvoiceHeader);//Auth Token ans Sek stored in Auth Table //IRN Encrypted with decrypted Sek that was decrypted by Appkey(Random 32-bit)

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

            jsonWriter2.WritePropertyName('Data');
            jsonWriter2.WriteValue(encryptedIRNPayload);



            finalPayload := jsonObjectlinq.ToString();
            // Message('FinalIRNPayload %1 ', finalPayload);
            Call_IRN_API(recAuthData, finalPayload, true, recSalesInvoiceHeader, false, false);
        end;

    end;

    procedure UpdateCancelDetails(txtIRN: Text; CancelDate: Text; recSIHeader: Record "Sales Invoice Header")
    var
        SIHeader: Record "Sales Invoice Header";
        txtCancelDate: text;
    begin
        SIHeader.get(recSIHeader."No.");
        SIHeader."IRN Hash" := txtIRN;
        txtCancelDate := ConvertAckDt(CancelDate);
        evaluate(SIHeader."E-Inv. Cancelled Date", txtCancelDate);
        SIHeader.Modify();

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    procedure Create_EInvoiceOnSalesOrderPost(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean)
    var
        recSIHeader: Record "Sales Invoice Header";
        recSalesCrmemHeader: Record "Sales Cr.Memo Header";
        CU_SalesCrEInvoice: Codeunit GST_Einvoice_CrMemo;
    begin
        if confirm('Do you want to create E-Invoice ?', true) then begin
            if SalesInvHdrNo <> '' then begin
                recSIHeader.get(SalesInvHdrNo);
                GenerateIRN_01(recSIHeader);
            end else
                if SalesCrMemoHdrNo <> '' then begin
                    recSalesCrmemHeader.get(SalesCrMemoHdrNo);
                    CU_SalesCrEInvoice.GenerateIRN_01(recSalesCrmemHeader);
                end
        end

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


    var
        myInt: Integer;
        JsonText: Text;
        IsInvoice: Boolean;
        DocumentNo: Text[20];
        SalesLineErr: Label 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.', Locked = true;

        JsonWriter: DotNet JsonTextWriter;
        GlobalNULL: Variant;
        CGSTLbl: Label 'CGST', Locked = true;
        SGSTLbl: label 'SGST', Locked = true;
        IGSTLbl: Label 'IGST', Locked = true;
        CESSLbl: Label 'CESS', Locked = true;
        BBQ_GSTIN: Label '29AAKCS3053N1ZS', Locked = true;
        gl_BillToPh: Code[20];
        OTHTxt: Label 'OTH';
        gl_BillToEm: Text[100];
        // JsonLObj: DotNet JObject;
        JsonLObj: DotNet JObject;
        // DocumentNoBlankErr: Label 'Document No. Blank';
        DocumentNoBlankErr: Label 'Document No. Blank';
}