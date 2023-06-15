//CITS_RS GST Invoice Field addition on Setup pages
pageextension 50230 Add_EInvoice_GSTRegNosPage extends "GST Registration Nos."
{
    layout
    {
        addafter("State Code")
        {
            field("E-Invoice Client ID"; "E-Invoice Client ID") { ApplicationArea = all; }
            field("E-Invoice Client Secret"; "E-Invoice Client Secret") { ApplicationArea = all; }
            field("E-Invoice Password"; "E-Invoice Password") { ApplicationArea = all; }
            field("E-Invoice UserName"; "E-Invoice UserName") { ApplicationArea = all; }
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