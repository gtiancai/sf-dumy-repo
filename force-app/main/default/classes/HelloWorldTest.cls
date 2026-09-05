@IsTest
public with sharing class HelloWorldTest {
    @IsTest
    static void testGreet() {
        String name = 'John';
        String expectedGreeting = 'Hello, John!';
        String actualGreeting = HelloWorld.greet(name);
        System.assertEquals(expectedGreeting, actualGreeting);
    }

    @IsTest
    static void testGreetWithTime() {
        String name = 'Jane';
        String actualGreeting = HelloWorld.greetWithTime(name);
        System.assert(actualGreeting.startsWith('Hello, Jane! Good '));
    }

    @IsTest
    static void testAddNumbers() {
        Integer a = 5;
        Integer b = 10;
        Integer expectedSum = 15;
        Integer actualSum = HelloWorld.addNumbers(a, b);
        System.assertEquals(expectedSum, actualSum);
    }
}
