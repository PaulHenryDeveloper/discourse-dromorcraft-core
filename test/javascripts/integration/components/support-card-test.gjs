import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import SupportCard from "discourse/plugins/discourse-dromorcraft-core/discourse/components/support-card";

function outletArgs(support) {
  return { model: { dromorcraft_support: support } };
}

const CARD = ".dromorcraft-support-card";

module("Integration | Component | support-card", function (hooks) {
  setupRenderingTest(hooks);

  test("shows the support data and the resources", async function (assert) {
    const args = outletArgs({
      launcher_version: "1.4.24",
      minecraft_version: "1.21.1",
      os: "windows",
      loader: "neoforge",
      latest_version: null,
      outdated: false,
      resources: ["errors", "java", "compatibility"],
    });

    await render(<template><SupportCard @outletArgs={{args}} /></template>);

    assert.dom(`${CARD} [data-key='launcher'] dd`).hasText("1.4.24");
    assert.dom(`${CARD} [data-key='minecraft'] dd`).hasText("1.21.1");
    assert.dom(`${CARD} [data-key='system'] dd`).hasText("Windows");
    assert.dom(`${CARD} [data-key='loader'] dd`).hasText("NeoForge");
    assert.dom(`${CARD} .dromorcraft-support-card__update`).doesNotExist();
    assert
      .dom(`${CARD} [data-resource='compatibility']`)
      .hasAttribute("href", "https://dromorcraft.com/resources/compatibility/")
      .hasText(i18n("dromorcraft_core.support_card.resources.compatibility"));
    assert.dom(`${CARD} [data-resource]`).exists({ count: 3 });
  });

  test("links an outdated launcher to the download page", async function (assert) {
    const args = outletArgs({
      launcher_version: "1.4.21",
      outdated: true,
      latest_version: "1.4.24",
      resources: ["updates", "errors", "java"],
    });

    await render(<template><SupportCard @outletArgs={{args}} /></template>);

    assert
      .dom(`${CARD} .dromorcraft-support-card__update`)
      .hasAttribute("href", "https://dromorcraft.com/download/")
      .hasText(
        i18n("dromorcraft_core.support_card.update", { version: "1.4.24" })
      );
  });

  test("leaves out what the topic doesn't have", async function (assert) {
    const args = outletArgs({ os: "linux", loader: "vanilla", resources: [] });

    await render(<template><SupportCard @outletArgs={{args}} /></template>);

    assert.dom(`${CARD} [data-key='launcher']`).doesNotExist();
    assert.dom(`${CARD} [data-key='minecraft']`).doesNotExist();
    assert
      .dom(`${CARD} [data-key='loader'] dd`)
      .hasText(i18n("dromorcraft_core.support_card.vanilla"));
    assert.dom(`${CARD} .dromorcraft-support-card__resources`).doesNotExist();
  });

  test("renders nothing for topics without support data", async function (assert) {
    const args = outletArgs(undefined);

    await render(<template><SupportCard @outletArgs={{args}} /></template>);

    assert.dom(CARD).doesNotExist();
  });
});
