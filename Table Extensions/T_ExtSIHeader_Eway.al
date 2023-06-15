// tableextension 50158 Eway_SalesHeader extends "Sales Invoice Header"
// {
//     fields
//     {

//         field(50000; "E-Way Bill Date"; DateTime) { DataClassification = ToBeClassified; }
//         field(50001; "E-Way Bill Valid Upto"; DateTime) { DataClassification = ToBeClassified; }

//         field(50002; "E-Invoice Cancel Remarks"; Text[100]) { DataClassification = ToBeClassified; }


//         field(50003; "E-Way Bill Cancel Reason"; Option)
//         {
//             DataClassification = ToBeClassified;
//             OptionMembers = " ","Duplicate Order","Order Cancelled","Other","Data Entry Mistake";
//             // OptionCaptionML = " ""Duplicate Order""Order Cancelled""Other""Data Entry Mistake"
//         }
//         field(50004; "E-Way Bill Cancel Remarks"; text[100]) { DataClassification = ToBeClassified; }
//         field(50005; "E-Invoice Cancel Reason"; Enum "E-Way Bill Cancel Reason_Enum") { DataClassification = ToBeClassified; }
//         field(50006; "E-Way Bill Cancel Date"; Text[100]) { DataClassification = ToBeClassified; }
//         // Add changes to table fields here


//     }

//     var
//         myInt: Integer;
// }

// /*"E-Way Bill Date"));
//             FieldRef1.VALUE := BillDate;
//             // FieldRef1 := RecRef1.FIELD(50001);//AckNum

//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill No."));
//             FieldRef1.VALUE := EwayBillNum;

//             dtText := CU_SalesInvoice.ConvertAckDt(EwayBillValid);
//             EVALUATE(ValidDate, dtText);
//             FieldRef1 := RecRef1.FIELD(TransferShipHeader.FieldNo("E-Way Bill Valid Upto"
//             */
