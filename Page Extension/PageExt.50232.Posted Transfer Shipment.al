pageextension 50232 PageExt50162 extends "Posted Transfer Shipment"
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

        modify("Transport Method") { Editable = true; }
        modify("Mode of Transport") { Editable = true; }
        modify("Shipment Method Code") { Editable = true; }

        // Add changes to page layout here
        addafter("Foreign Trade")
        {
            group("E-Invoice")
            {
                field("Irn No."; "Irn No.")
                {
                    ApplicationArea = All;
                }
                field("Acknowledgement No."; "Acknowledgement No.")
                {
                    ApplicationArea = all;
                }
                field("Acknowledgement Date"; "Acknowledgement Date")
                {
                    ApplicationArea = all;
                }
                field("QR Code"; "QR Code")
                {
                    ApplicationArea = All;
                }
                field("E-Invoice Cancel Date"; "E-Invoice Cancel Date") { ApplicationArea = all; }
                field("E-Invoice Cancel Reason"; "E-Invoice Cancel Reason") { ApplicationArea = all; }
                field("E-Invoice Cancel Remarks"; "E-Invoice Cancel Remarks") { ApplicationArea = all; }

            }
            group("E-Way Bill")
            {
                field("E-Way Bill No."; "E-Way Bill No.")
                {
                    ApplicationArea = all;
                }
                field("E-Way Bill Date"; "E-Way Bill Date")
                {
                    ApplicationArea = all;
                }
                field("E-Way Bill Valid Upto"; "E-Way Bill Valid Upto")
                {
                    ApplicationArea = all;
                }
                field("E-Way Bill Remarks"; "E-Way Bill Remarks")
                {
                    ApplicationArea = all;
                }

                field("E-Way Bill Cancel Date"; "E-Way Bill Cancel Date") { ApplicationArea = all; }
                // field("E-Way Bill Cancel Reason"; "E-Way Bill Cancel Reason") { Enabled = false; HideValue = true; ApplicationArea = all; }
                field("E-Way Bill Cancel Remarks"; "E-Way Bill Cancel Remarks") { ApplicationArea = all; }
                field("E-Way Cancel Reason"; "E-Way Cancel Reason") { ApplicationArea = all; }
            }


        }
    }


    actions
    {
        // Add changes to page actions here
        addafter("Attached Gate Entry")
        {

            action("Generate IRN")
            {
                ApplicationArea = All;

                Caption = 'Generate E Invoice';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    CU_EInvoice: Codeunit GST_Einvoice_CrMemo;
                    CU_EInvoiceTransfer: Codeunit E_Invoice_TransferShipments;
                    recSalesInvoice: Record "Sales Invoice Header";
                begin
                    CU_EInvoiceTransfer.GenerateIRN(Rec);
                end;
            }
            action("Cancel IRN")
            {
                ApplicationArea = All;

                Caption = 'Cancel E Invoice';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    CU_EINvoiceTransfer: Codeunit E_Invoice_TransferShipments;
                begin
                    CU_EINvoiceTransfer.CancelIRN_Transfer(Rec);

                end;
            }
            // action("Update IRN")
            // {
            //     ApplicationArea = All;

            //     trigger OnAction()
            //     begin
            //         a := b;
            //     end;
            // }
            action("Generate E-Way Bill")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_WayBill_Transfer: Codeunit E_WayBill_Transfer;
                begin
                    E_WayBill_Transfer.GenerateEwayBill(Rec);
                end;
            }
            action("Cancel E-Way Bill")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_WayBill_Transfer: Codeunit E_WayBill_Transfer;
                begin
                    E_WayBill_Transfer.CancelEWayBill(Rec);
                end;
            }
            action("GenerateEwaybllWithoutIRN")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'E Way Bill without IRN';
                PromotedIsBig = true;
                Image = Invoice;

                trigger OnAction()
                var
                    E_WayBill_Transfer: Codeunit E_WayBill_Transfer;
                begin
                    E_WayBill_Transfer.GenerateEwaybllWithoutIRN(Rec);
                end;
            }
        }
    }

    var
        myInt: Integer;
        a: Integer;
        b: Integer;
}