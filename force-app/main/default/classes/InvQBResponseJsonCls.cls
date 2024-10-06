public class InvQBResponseJsonCls{
	public Integer statusCode;	//200
	public cls_invoices[] invoices;
	public class cls_invoices {
		public cls_TxnTaxDetail TxnTaxDetail;
		public String TxnDate;	//2021-08-11
		public Double TotalAmt;	//110
		public String SyncToken;	//0
		public boolean sparse;
		public String SFRecordID;	//a0A5j000000u97uEAA
		public cls_MetaData MetaData;
		public cls_Line[] Line;
		public String Id;	//158
		public String EmailStatus;	//NotSet
		public String DueDate;	//2021-09-11
		public String DocNumber;	//Inv-1201
		public cls_CustomField[] CustomField;
		public cls_CustomerRef CustomerRef;
		public cls_CurrencyRef CurrencyRef;
		public cls_BillAddr BillAddr;
		public Double Balance;	//110
		public boolean AllowOnlineCreditCardPayment;
		public boolean AllowOnlineACHPayment;
	}
	public class cls_TxnTaxDetail {
		public Double TotalTax;	//0
	}
	public class cls_MetaData {
		public String LastUpdatedTime;	//2021-11-01T02:40:26-07:00
		public String CreateTime;	//2021-11-01T02:40:26-07:00
	}
	public class cls_Line {
		public cls_SalesItemLineDetail SalesItemLineDetail;
		public Integer LineNum;	//1
		public String Id;	//1
		public String DetailType;	//SalesItemLineDetail
		public String Description;	//Description
		public Double Amount;	//100
	}
	public class cls_SalesItemLineDetail {
		public Double UnitPrice;	//50
		public cls_TaxCodeRef TaxCodeRef;
		public String ServiceDate;	//1993-05-25
		public Double Qty;	//2
		public cls_ItemRef ItemRef;
	}
	public class cls_TaxCodeRef {
		public String value;	//TAX
	}
	public class cls_ItemRef {
		public String value;	//1
		public String name;	//Services
	}
	public class cls_CustomField {
		public String Type;	//StringType
		public String StringValue;	//Received
		public String Name;	//Crew #
		public String DefinitionId;	//1
	}
	public class cls_CustomerRef {
		public String value;	//29
		public String name;	//Weiskopf Consulting
	}
	public class cls_CurrencyRef {
		public String value;	//USD
		public String name;	//United States Dollar
	}
	public class cls_BillAddr {
		public String PostalCode;	//508238
		public String Line3;	//Kodad
		public String Line2;	//First Lane
		public String Line1;	//1-24
		public String Id;	//132
		public String Country;	//India
		public String City;	//Suryapet
	}
	/*

	static testMethod void testParse() {
		String json=		'{'+
		'	"statusCode": 200,'+
		'	"invoices": [{'+
		'		"TxnTaxDetail": {'+
		'			"TotalTax": 0'+
		'		},'+
		'		"TxnDate": "2021-08-11",'+
		'		"TotalAmt": 110.00,'+
		'		"SyncToken": "0",'+
		'		"sparse": false,'+
		'		"SFRecordID": "a0A5j000000u97uEAA",'+
		'		"MetaData": {'+
		'			"LastUpdatedTime": "2021-11-01T02:40:26-07:00",'+
		'			"CreateTime": "2021-11-01T02:40:26-07:00"'+
		'		},'+
		'		"Line": [{'+
		'				"SalesItemLineDetail": {'+
		'					"UnitPrice": 50,'+
		'					"TaxCodeRef": {'+
		'						"value": "TAX"'+
		'					},'+
		'					"ServiceDate": "1993-05-25",'+
		'					"Qty": 2,'+
		'					"ItemRef": {'+
		'						"value": "1",'+
		'						"name": "Services"'+
		'					}'+
		'				},'+
		'				"LineNum": 1,'+
		'				"Id": "1",'+
		'				"DetailType": "SalesItemLineDetail",'+
		'				"Description": "Description",'+
		'				"Amount": 100.00'+
		'			},'+
		'			{'+
		'				"DetailType": "SubTotalLineDetail",'+
		'				"Amount": 100.00'+
		'			},'+
		'			{'+
		'				"DetailType": "SalesItemLineDetail",'+
		'				"Amount": 10.00,'+
		'				"SalesItemLineDetail": {'+
		'					"TaxCodeRef": {'+
		'						"value": "TAX"'+
		'					},'+
		'					"ItemRef": {'+
		'						"value": "SHIPPING_ITEM_ID"'+
		'					}'+
		'				}'+
		'			}'+
		'		],'+
		'		"Id": "158",'+
		'		"EmailStatus": "NotSet",'+
		'		"DueDate": "2021-09-11",'+
		'		"DocNumber": "Inv-1201",'+
		'		"CustomField": [{'+
		'			"Type": "StringType",'+
		'			"StringValue": "Received",'+
		'			"Name": "Crew #",'+
		'			"DefinitionId": "1"'+
		'		}],'+
		'		"CustomerRef": {'+
		'			"value": "29",'+
		'			"name": "Weiskopf Consulting"'+
		'		},'+
		'		"CurrencyRef": {'+
		'			"value": "USD",'+
		'			"name": "United States Dollar"'+
		'		},'+
		'		"BillAddr": {'+
		'			"PostalCode": "508238",'+
		'			"Line3": "Kodad",'+
		'			"Line2": "First Lane",'+
		'			"Line1": "1-24",'+
		'			"Id": "132",'+
		'			"Country": "India",'+
		'			"City": "Suryapet"'+
		'		},'+
		'		"Balance": 110.00,'+
		'		"AllowOnlineCreditCardPayment": false,'+
		'		"AllowOnlineACHPayment": false'+
		'	}]'+
		'}';
		fromJSON obj = parse(json);
		System.assert(obj != null);
	}*/
}