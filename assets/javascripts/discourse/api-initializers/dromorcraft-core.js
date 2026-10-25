import { apiInitializer } from "discourse/lib/api";
import OutdatedNotice from "../components/outdated-notice.gjs";
import SupportCard from "../components/support-card.gjs";

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.dromorcraft_core_enabled) {
    return;
  }

  // Above the post stream, so the card sits right on top of the first post.
  api.renderInOutlet("topic-above-posts", SupportCard);

  // Only the notices this plugin wrote (OutdatedNotice::MARKER); staff notices keep core's look.
  api.registerValueTransformer("post-notice-component", ({ value, context }) =>
    context.post?.notice?.dromorcraft === "outdated" ? OutdatedNotice : value
  );
});
