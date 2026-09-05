public class HelloWorld {
    public static String greet(String name) {
        return 'Hello, ' + name + '!';
    }

    public static String greetWithTime(String name) {
        String greeting = greet(name);
        String timeOfDay = getTimeOfDay();
        return greeting + ' Good ' + timeOfDay + '!';
    }

    public static Integer addNumbers(Integer a, Integer b) {
        System.debug(a + ' + ' + b + ' = ' + (a + b));
        return a + b;
    }
}
