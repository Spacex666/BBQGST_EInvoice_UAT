tableextension 50175 AddGSTUOMNew extends "Unit of Measure"
{
    fields
    {
        // field(50110; "GST UOM"; Code[10])
        // {
        //     DataClassification = ToBeClassified;
        //     ObsoleteState = Removed;
        //     ObsoleteReason = 'Ambiguous';
        // }
        //         // field(50111; "GST UOM_N"; Code[10]) { DataClassification = ToBeClassified; }
        // Add changes to table fields here

        field(50002; "E-Inv UOM"; code[10]) { DataClassification = ToBeClassified; }
    }

    var
        myInt: Integer;
}