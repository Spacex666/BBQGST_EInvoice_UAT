tableextension 50172 ShipmentMethod_EWay extends "Shipment Method"
{
    fields
    {
        field(50000; "GST Trans Mode"; Code[2]) { DataClassification = ToBeClassified; }
        // Add changes to table fields here
    }

    var
        myInt: Integer;
}