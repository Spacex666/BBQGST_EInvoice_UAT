tableextension 50171 AddEInvoiceCred_GSTRegNum extends "GST Registration Nos."
{
    fields
    {
        // Add changes to table fields here
        field(50000; "E-Invoice UserName"; Code[100])
        {
            Description = 'CITS_RS E-Invoicing';
            DataClassification = ToBeClassified;
        }
        field(50001; "E-Invoice Password"; Text[100])
        {
            Description = 'CITS_RS E-Invoicing';
            DataClassification = ToBeClassified;
        }
        field(50002; "E-Invoice Client Secret"; Text[100])
        {
            Description = 'CITS_RS E-Invoicing';
            DataClassification = ToBeClassified;
        }
        field(50003; "E-Invoice Client ID"; Text[100])
        {
            Description = 'CITS_RS E-Invoicing';
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}