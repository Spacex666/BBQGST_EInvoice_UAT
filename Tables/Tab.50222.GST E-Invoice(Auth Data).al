Table 50222 "GST E-Invoice(Auth Data)"
{

    fields
    {
        field(1; "Sr No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Auth Token"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(3; SEK; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Insertion DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Expiry Date Time"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(6; PlainAppKey; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(7; DecryptedSEK; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(8; DocumentNum; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Token Duration"; Time)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Expiry Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Sr No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

