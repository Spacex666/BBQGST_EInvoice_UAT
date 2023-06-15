pageextension 50228 ShipMethod_EWay extends "Shipment Methods"
{
    layout
    {
        addafter(Description)
        {
            field("GST Trans Mode"; "GST Trans Mode") { ApplicationArea = all; }
        }
        // Add changes to page layout here
    }


    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}