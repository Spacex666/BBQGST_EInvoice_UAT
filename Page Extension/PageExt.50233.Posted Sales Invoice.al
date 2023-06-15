pageextension 50233 PageExt50131 extends "Posted Sales Invoice"
{
    layout
    {

        modify("Shipping Agent Code")
        {
            Editable = true;
        }
        modify("Vehicle No.")
        {
            Editable = true;
        }
        modify("Shipment Method Code") { Editable = true; }

        modify("Transport Method") { Editable = true; }
        modify("Mode of Transport") { Editable = true; }

        addafter("IRN Hash")
        {
            field("E-Invoice QR Code"; "E-Invoice QR Code") { ApplicationArea = all; }
            field("E-Invoice Cancel Reason"; "E-Invoice Cancel Reason") { ApplicationArea = all; }
            field("E-Invoice Cancel Remarks"; "E-Invoice Cancel Remarks") { ApplicationArea = all; }


            field("E-Way Bill Date"; "E-Way Bill Date") { ApplicationArea = all; }
            // field("E-Way Bill No.";"E-Way Bill No."){ApplicationArea=all;}
            field("E-Way Bill Valid Upto"; "E-Way Bill Date") { ApplicationArea = all; }
            field("E-Way Bill Cancel Date"; "E-Way Bill Cancel Date") { ApplicationArea = all; }
            field("E-Way Bill Cancel Reason"; "E-Way Bill Cancel Reason") { ApplicationArea = all; }
            field("E-Way Bill Cancel Remarks"; "E-Way Bill Cancel Remarks") { ApplicationArea = all; }
            // field("QR Code";"QR Code")
            // field("E-Inv. Cancelled Date";"E-Inv. Cancelled Date"){ApplicationArea=all;}


        }
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Generate IRN")
        {
            action("Generate IRN2")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Generate E-Invoice';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_Invoice_New: Codeunit E_Invoice_SalesInvoice;//CITS_RS
                    recSalesCrMemo: Record "Sales Cr.Memo Header";
                begin
                    // EInv.IntialiseAccesToken();
                    // EInv.Run();
                    // EInv.GenerateIRN_01(Rec);
                    E_Invoice_New.GenerateIRN_01(Rec);
                end;
            }

            action("Cancel IRN")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Cancel E-Invoice';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_Invoice_New: Codeunit E_Invoice_SalesInvoice;//CITS_RS                   
                begin

                    E_Invoice_New.CancelSalesE_Invoice(Rec);
                end;

            }

            action("Generate E-Wy Bill")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Generate E-Way Bill';
                PromotedIsBig = true;
                Image = Invoice;
                trigger OnAction()
                var

                    E_WayBill_Sales: Codeunit Generate_EWayBill_SalesInvoice;
                begin

                    E_WayBill_Sales.GenerateEwayBill(Rec);

                end;
            }

            action("Cancel E-Way Bill")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Cancel E-Way Bill';
                PromotedIsBig = true;
                Image = Invoice;
                trigger OnAction()
                var
                    E_WayBill_Sales: Codeunit Generate_EWayBill_SalesInvoice;
                begin

                    E_WayBill_Sales.CancelEWayBill(Rec);

                end;
            }
        }
    }

    var
        myInt: Integer;
}