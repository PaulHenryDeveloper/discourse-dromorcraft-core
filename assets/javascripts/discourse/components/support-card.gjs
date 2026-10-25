import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

const SITE = "https://dromorcraft.com";

// Systems and loaders keep their projects' spelling; only "vanilla" is translated.
const NAMES = {
  windows: "Windows",
  linux: "Linux",
  fabric: "Fabric",
  quilt: "Quilt",
  forge: "Forge",
  neoforge: "NeoForge",
};

function displayName(value) {
  if (value === "vanilla") {
    return i18n("dromorcraft_core.support_card.vanilla");
  }
  return NAMES[value];
}

// The data the plugin stored for a support topic (topic view `dromorcraft_support`), shown
// above the first post with links to the site's resource pages.
export default class SupportCard extends Component {
  get support() {
    return this.args.outletArgs?.model?.dromorcraft_support;
  }

  get rows() {
    const support = this.support;
    return [
      ["minecraft", support.minecraft_version],
      ["system", displayName(support.os)],
      ["loader", displayName(support.loader)],
    ]
      .filter(([, value]) => value)
      .map(([key, value]) => ({
        key,
        label: i18n(`dromorcraft_core.support_card.${key}`),
        value,
      }));
  }

  get resources() {
    return (this.support.resources ?? []).map((id) => ({
      id,
      url: `${SITE}/resources/${id}/`,
      title: i18n(`dromorcraft_core.support_card.resources.${id}`),
    }));
  }

  get downloadUrl() {
    return `${SITE}/download/`;
  }

  <template>
    {{#if this.support}}
      <section class="dromorcraft-support-card">
        <h2 class="dromorcraft-support-card__title">
          {{i18n "dromorcraft_core.support_card.title"}}
        </h2>

        <dl class="dromorcraft-support-card__data">
          {{#if this.support.launcher_version}}
            <div class="dromorcraft-support-card__item" data-key="launcher">
              <dt>{{i18n "dromorcraft_core.support_card.launcher"}}</dt>
              <dd>
                {{this.support.launcher_version}}
                {{#if this.support.outdated}}
                  <a
                    class="dromorcraft-support-card__update"
                    href={{this.downloadUrl}}
                  >
                    {{i18n
                      "dromorcraft_core.support_card.update"
                      version=this.support.latest_version
                    }}
                  </a>
                {{/if}}
              </dd>
            </div>
          {{/if}}
          {{#each this.rows as |row|}}
            <div class="dromorcraft-support-card__item" data-key={{row.key}}>
              <dt>{{row.label}}</dt>
              <dd>{{row.value}}</dd>
            </div>
          {{/each}}
        </dl>

        {{#if this.resources.length}}
          <div class="dromorcraft-support-card__resources">
            <span id="dromorcraft-support-card-resources">
              {{i18n "dromorcraft_core.support_card.might_help"}}
            </span>
            <ul aria-labelledby="dromorcraft-support-card-resources">
              {{#each this.resources as |resource|}}
                <li>
                  <a data-resource={{resource.id}} href={{resource.url}}>
                    {{resource.title}}
                  </a>
                </li>
              {{/each}}
            </ul>
          </div>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
