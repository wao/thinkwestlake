package <%= package_name %>;

import android.app.Activity;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricGradleTestRunner;
import org.robolectric.annotation.Config;

import static org.junit.Assert.assertTrue;

@RunWith(RobolectricGradleTestRunner.class)
@Config(constants = BuildConfig.class)
public class <%= class_name %> {

  @org.junit.Test
  public void titleIsCorrect() throws Exception {
    Activity activity = Robolectric.setupActivity(<%= activity_name %>_.class);
    assertTrue(activity.getTitle().toString().equals("<%= app_name %>"));
  }
}
