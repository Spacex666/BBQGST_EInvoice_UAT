tableextension 50169 SalesCrMemoGSTEInvoice extends "Sales Cr.Memo Header"
{
    fields
    {
        field(50000; "E-Invoice Cancel Remarks"; Text[100]) { DataClassification = ToBeClassified; }
        field(50001; "E-Invoice QR Code"; blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Bitmap;
            Description = 'CITS_RS E-Invoice';

        }

        // Add changes to table fields here
    }

    var
        myInt: Integer;
}