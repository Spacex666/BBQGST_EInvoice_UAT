tableextension 50167 GSTEInvoice_GenLedger extends "General Ledger Setup"
{
    fields
    {

        field(50031; "E_Way Bill URL"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'CITS_RS(E-Invoicing)';
        }

        field(50032; "Cancel E-Invoice URL"; Text[100]) { DataClassification = ToBeClassified; }
        field(50033; "Cancel E-Way Bill"; Text[100]) { DataClassification = ToBeClassified; }
        field(50034; "EWAYBILL w/o IRN"; Text[75]) { DataClassification = ToBeClassified; }
        /*
        field(50000; "Use Batch Posting"; Boolean)
        {
            Description = '01268';()
        }
        field(50001; "Interval In Seconds"; Integer)
        {
            Description = '01268';
        }
        field(50002; "Integration Posting Template"; Code[20])
        {
            Description = 'ONINT';
            TableRelation = "Gen. Journal Template";
        }
        field(50003; "Integration Posting Batch"; Code[20])
        {
            Description = 'ONINT';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Integration Posting Template"));
        }
        field(50004; "Post Salary Auto"; Boolean)
        {
            Description = 'ONPAYINT';
        }
        field(50005; "Post Credit Card Entry Auto"; Boolean)
        {
            Description = '02376';
        }
        field(50006; "Credit Entry Account No"; Code[20])
        {
            Description = '2376';
        }
        field(50007; "E-mail To"; Text[30])
        {
            Description = 'ONINT';
        }
        field(50008; "E-mail CC"; Text[250])
        {
            Description = 'ONINT';
        }
        field(50009; "E-mail Subject"; Text[30])
        {
            Description = 'ONINT';
        }
        field(50010; "E-mail Body"; Text[50])
        {
            Description = 'ONINT';
        }
        field(50011; "Common Allocation Customer No."; Code[20])
        {
            Description = 'ONONALLOC';
            TableRelation = Customer;
        }
        field(50012; "Global Dim. Wise Con. Check"; Boolean)
        {
            Caption = 'Global Dimension 1 Wise Consistency Check';
        }
        field(50013; "Commission G/L Account No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = '511';
            TableRelation = "G/L Account" WHERE("Direct Posting" = CONST(true));
        }
        field(50014; "Month End Closing Date"; Date)
        {
            DataClassification = ToBeClassified;
            Description = '935';
        }
        field(50015; "Integration Posting Batch1"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'Added By Ghanshyam for UBQ';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Integration Posting Template"));
        }
        field(50016; "Attachment on Bank"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3150';
        }
        field(50017; "Attachment on JV"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3150';
        }
        field(50018; "Attachment on Gen. Jnl"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3150';
        }
        field(50019; "Attachment on Contra"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3150';
        }
        field(50020; "Attachment on Recurring"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3150';
        }
        field(50021; "Attachment on Cash"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3150';
        }
        field(50022; "Bank Pay Application Mandatory"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3162';
        }
        field(50023; "Enable G/L Unapply"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = '3587';
        }
        field(50024; "Prov. G/L Account"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = '3587';
            TableRelation = "G/L Account";
        }
        field(50025; "Duplicate BRS Creation"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'CCIT for Duplicate BRS';
        }
        field(50026; "Prov. Reversal Template"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = '3587';
            TableRelation = "Gen. Journal Template".Name WHERE(Type = CONST(General));
        }
        field(50027; "Post Sales Integration Auto"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(50028; "GST Public Key Directory Path"; Text[250])
        {
            DataClassification = ToBeClassified;
            Description = 'CITS_RS(E-Invoicing)';
        }
        field(50029; "GST Authorization URL"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'CITS_RS(E-Invoicing)';
        }
        field(50030; "GST IRN Generation URL"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'CITS_RS(E-Invoicing)';
        }*/




    }

    var
        myInt: Integer;
}