public class InvocableChargeCustomerByFlow {
    @InvocableMethod(label='chargeCustomer' description='Return charge Customer')
    public static void chargeCustomer(List<ID> Ids){
        if(Ids.size()>0){
            chargeCustomer.charge(Ids[0]);
        }     
    }
}