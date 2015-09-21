package <%= package_name %>;

import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import android.test.suitebuilder.annotation.LargeTest;
import android.support.test.runner.AndroidJUnit4;
import android.support.test.rule.ActivityTestRule;

import <%= original_package_name %>.*;

import android.support.test.internal.util.AndroidRunnerParams;

import static android.support.test.espresso.Espresso.onView;
import static android.support.test.espresso.assertion.ViewAssertions.matches;
import static android.support.test.espresso.matcher.ViewMatchers.*;
import static org.hamcrest.core.StringEndsWith.*;

@RunWith(AndroidJUnit4.class)
public class <%= class_name %>{

    @Rule
    public ActivityTestRule<MainActivity_> mActivityRule = new ActivityTestRule<>(
            MainActivity_.class);

    @Test
    public void testActivity() {
        onView(withClassName(endsWith("TextView"))).check(matches(withText("Hello world!")));
    }
}

