public class CusQBResponseJsonCls{
    public Integer statusCode;	//200
    public cls_errors[] errors;
    public cls_customers[] customers;
    class cls_errors {}
    class cls_customers {
        public boolean Taxable;
        public String SyncToken;	//0
        public boolean sparse;
        public String SFRecordId;
        public String salesforceRecordId;
        public cls_ShipAddr ShipAddr;
        public String PrintOnCheckName;	//Breadwinner Company
        public cls_PrimaryPhone PrimaryPhone;
        public String PreferredDeliveryMethod;	//Print
        public cls_Metadata Metadata;
        public boolean Job;
        public String Id;	//63
        public String FullyQualifiedName;	//Breadwinner Company
        public String DisplayName;	//Breadwinner Company
        public cls_DefaultTaxCodeRef DefaultTaxCodeRef;
        public cls_CurrencyRef CurrencyRef;
        public String CompanyName;	//Breadwinner Company
        public boolean BillWithParent;
        public cls_BillAddr BillAddr;
        public String BalanceWithJobs;	//0
        public String Balance;	//0
        public String Active;	//true
    }
    class cls_ShipAddr {
        public String PostalCode;	//500008
        public String Line2;	//Srinagar Colony
        public String Line1;	//1/78-24
        public String Id;	//125
        public String Country;	//India
        public String City;	//Hyderabad
    }
    class cls_PrimaryPhone {
        public String FreeFormNumber;	//9988543562
    }
    class cls_Metadata {
        public String LastUpdatedTime;	//2021-10-29T21:14:53-07:00
        public String CreateTime;	//2021-10-29T21:14:53-07:00
    }
    class cls_DefaultTaxCodeRef {
        public String value;	//2
    }
    class cls_CurrencyRef {
        public String value;	//USD
        public String name;	//United States Dollar
    }
    class cls_BillAddr {
        public String PostalCode;	//508238
        public String Line3;	//Kodad
        public String Line2;	//First Lane
        public String Line1;	//1-24
        public String Id;	//124
        public String Country;	//India
        public String City;	//Suryapet
    }
    
    /*
static testMethod void testParse() {
String json=		'{'+
'    "statusCode": 200,'+
'    "errors": [],'+
'    "customers": ['+
'      {'+
'        "Taxable": true,'+
'        "SyncToken": "0",'+
'        "sparse": false,'+
'        "ShipAddr": {'+
'          "PostalCode": "500008",'+
'          "Line2": "Srinagar Colony",'+
'          "Line1": "1/78-24",'+
'          "Id": "125",'+
'          "Country": "India",'+
'          "City": "Hyderabad"'+
'        },'+
'        "PrintOnCheckName": "Breadwinner Company",'+
'        "PrimaryPhone": {'+
'          "FreeFormNumber": "9988543562"'+
'        },'+
'        "PreferredDeliveryMethod": "Print",'+
'        "Metadata": {'+
'          "LastUpdatedTime": "2021-10-29T21:14:53-07:00",'+
'          "CreateTime": "2021-10-29T21:14:53-07:00"'+
'        },'+
'        "Job": false,'+
'        "Id": "63",'+
'        "FullyQualifiedName": "Breadwinner Company",'+
'        "DisplayName": "Breadwinner Company",'+
'        "DefaultTaxCodeRef": {'+
'          "value": "2"'+
'        },'+
'        "CurrencyRef": {'+
'          "value": "USD",'+
'          "name": "United States Dollar"'+
'        },'+
'        "CompanyName": "Breadwinner Company",'+
'        "BillWithParent": false,'+
'        "BillAddr": {'+
'          "PostalCode": "508238",'+
'          "Line3": "Kodad",'+
'          "Line2": "First Lane",'+
'          "Line1": "1-24",'+
'          "Id": "124",'+
'          "Country": "India",'+
'          "City": "Suryapet"'+
'        },'+
'        "BalanceWithJobs": "0",'+
'        "Balance": "0",'+
'        "Active": "true"'+
'      }'+
'    ]'+
'  }';
CusQBResponseJsonCls obj = parse(json);
System.assert(obj != null);
}
*/
}