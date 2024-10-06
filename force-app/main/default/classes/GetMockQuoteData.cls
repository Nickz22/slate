public class GetMockQuoteData {
    public static List<Map<String, Object>> getMockPricingTables() {
        Map<String, Object> table = new Map<String, Object>{
            'name' => 'Pricing Table - Cam Design - 11.04.20',
            'data_merge' => true,
            'options' => new Map<String, Object>{
                'Tax' => new Map<String, Object>{
                    'is_global' => true,
                    'type' => 'absolute',
                    'name' => 'Tax',
                    'value' => 2.4
                }
            },
            'sections' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'title' => 'Sample Section',
                    'default' => true,
                    'rows' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'options' => new Map<String, Object>{
                                'optional' => true,
                                'optional_selected' => true,
                                'qty_editable' => true
                            },
                            'data' => new Map<String, Object>{
                                'Name' => 'Toy Panda',
                                'Description' => 'Fluffy!',
                                'Text_Unit_Cost__c' => 10,
                                'Text_Customer_Price__c' => 8,
                                'Quantity' => 3,
                                'Price' => 30,
                                'Days_Required__c' => 4
                            }
                        }
                    }
                }
            }
        };

        return new List<Map<String, Object>>{ table };
    }
}