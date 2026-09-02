public class HelloWorld {
    public static String greet(String name) {
        return 'Hello, ' + name + '!';
    }

    public static Integer addNumbers(Integer a, Integer b) {
        System.debug(a + ' + ' + b + ' = ' + (a + b));
        return a + b;
    }
}
