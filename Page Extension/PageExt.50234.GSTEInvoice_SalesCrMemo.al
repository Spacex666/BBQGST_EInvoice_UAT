pageextension 50234 Add_EInvoice_SalesCrMemo extends "Posted Sales Credit Memo"
{
    layout
    {
        addafter("IRN Hash")
        {
            field("E-Invoice QR Code"; "E-Invoice QR Code") { ApplicationArea = all; }
        }
        addafter("Cancel Reason")
        {
            field("E-Invoice Cancel Remarks"; "E-Invoice Cancel Remarks") { ApplicationArea = all; }
            // field("E-Inv. Cancelled Date";"E-Inv. Cancelled Date")
        }
        // Add changes to page layout here
    }

    actions
    {
        addafter("Generate E-Invoice")
        {
            action(E_InvoiceGen)
            {
                Caption = 'Generate E Invoice_NIC';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    CU_EInvoice: Codeunit GST_Einvoice_CrMemo;
                    recSalesInvoice: Record "Sales Invoice Header";
                begin
                    CU_EInvoice.GenerateIRN_01(Rec);

                end;
            }
            action("Cancel E-Invoice")
            {
                Caption = 'Cancel E-Invoice';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    CU_EInvoice: Codeunit GST_Einvoice_CrMemo;
                    recSalesInvoice: Record "Sales Invoice Header";
                begin
                    CU_EInvoice.CancelSalesCrMemo_IRN(Rec);

                end;
            }
        }
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}