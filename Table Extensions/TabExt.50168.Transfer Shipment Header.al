tableextension 50168 E_InvoiceTransferShipment extends "Transfer Shipment Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Irn No."; code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(50001; "Acknowledgement No."; Code[100])
        {
            DataClassification = ToBeClassified;
        }

        field(50002; "Acknowledgement Date"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(50003; "QR Code"; Blob)
        {
            Caption = 'E-Invoice QR';
            DataClassification = ToBeClassified;
            Subtype = Bitmap;
            Description = 'CITS_RS E-Invoice';
        }
        field(50004; "E-Way Bill No."; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(50005; "E-Way Bill Date"; datetime)
        {
            DataClassification = ToBeClassified;
        }
        field(50006; "E-Way Bill Valid Upto"; datetime)
        {
            DataClassification = ToBeClassified;
        }
        field(50007; "E-Way Bill Remarks"; Text[100])
        {
            DataClassification = ToBeClassified;
        }

        field(50008; "E-Invoice Cancel Remarks"; Text[100]) { DataClassification = ToBeClassified; }
        field(50009; "E-Invoice Cancel Date"; DateTime) { DataClassification = ToBeClassified; }
        field(50010; "E-Invoice Cancel Reason"; Option)
        {

            DataClassification = ToBeClassified;
            OptionMembers = " ","Duplicate Order","Order Cancelled","Other","Data Entry Mistake";
            // OptionCaptionML = " ""Duplicate Order""Order Cancelled""Other""Data Entry Mistake"
        }
        field(50011; "E-Way Bill Cancel Reason"; Option)
        {
            Enabled = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Used Enum instead of Option';
            DataClassification = ToBeClassified;
            OptionMembers = " ","Duplicate Order","Order Cancelled","Other","Data Entry Mistake";
            // OptionCaptionML = " ""Duplicate Order""Order Cancelled""Other""Data Entry Mistake"
        }

        field(50012; "E-Way Bill Cancel Remarks"; text[100]) { DataClassification = ToBeClassified; }
        field(50013; "E-Way Cancel Reason"; Enum "E-Way Bill Cancel Reason_Enum") { DataClassification = ToBeClassified; }
        field(50014; "E-Way Bill Cancel Date"; Text[100]) { DataClassification = ToBeClassified; }
        // Add changes to table fields here
        /*
        field(50000; "Irn No."; code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(50001; "Acknowledgement No."; Code[100])
        {
            DataClassification = ToBeClassified;
        }

        field(50002; "Acknowledgement Date"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(50003; "QR Code"; Blob)
        {
            DataClassification = ToBeClassified;
        }
         field(50004; "E-Way Bill No."; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(50005;"E-Way Bill Date";datetime)
        {
           DataClassification = ToBeClassified; 
        }
        field(50006;"E-Way Bill Valid Upto";datetime)
        {
           DataClassification = ToBeClassified; 
        }*/




    }

    var
        myInt: Integer;
}