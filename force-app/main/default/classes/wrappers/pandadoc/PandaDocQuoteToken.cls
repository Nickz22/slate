/**
 * @description Wrapper for a PandaDoc quote token which are used to inject live data into placeholders
 */
public class PandaDocQuoteToken {

    public String name;
    public Object value;

    public PandaDocQuoteToken(String name, Object value) {
        this.name = name;
        this.value = value;
    }
}