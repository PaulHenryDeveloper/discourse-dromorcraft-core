import { trustHTML } from "@ember/template";
import dIcon from "discourse/ui-kit/helpers/d-icon";

// The plugin's outdated-launcher notice, in place of core's custom notice. Core shows those with
// a staff shield on a danger background; this one is information, not a warning from staff.
const OutdatedNotice = <template>
  {{dIcon "circle-info"}}
  <div class="post-notice-message dromorcraft-outdated-notice">
    {{trustHTML @notice.cooked}}
  </div>
</template>;

export default OutdatedNotice;
