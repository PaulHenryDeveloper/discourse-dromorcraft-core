import { apiInitializer } from "discourse/lib/api";
import SupportCard from "../components/support-card.gjs";

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.dromorcraft_core_enabled) {
    return;
  }

  // Above the post stream, so the card sits right on top of the first post.
  api.renderInOutlet("topic-above-posts", SupportCard);
});
