import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import OutdatedNotice from "discourse/plugins/discourse-dromorcraft-core/discourse/components/outdated-notice";

module("Integration | Component | outdated-notice", function (hooks) {
  setupRenderingTest(hooks);

  test("shows the cooked notice with an info icon", async function (assert) {
    const notice = {
      type: "custom",
      dromorcraft: "outdated",
      cooked:
        '<p>This was reported on launcher 1.4.21, and 1.4.24 is out. <a href="https://dromorcraft.com/download/">Update the launcher</a></p>',
    };

    await render(<template><OutdatedNotice @notice={{notice}} /></template>);

    assert.dom(".dromorcraft-outdated-notice").includesText("1.4.24 is out");
    assert
      .dom(".dromorcraft-outdated-notice a")
      .hasAttribute("href", "https://dromorcraft.com/download/");
    assert.dom(".d-icon-circle-info").exists();
    assert.dom(".d-icon-user-shield").doesNotExist();
  });
});
