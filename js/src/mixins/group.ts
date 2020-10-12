import { PERSON_MEMBERSHIPS, CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { FETCH_GROUP } from "@/graphql/group";
import { Group, IActor, IGroup, IPerson, MemberRole } from "@/types/actor";
import { Component, Vue } from "vue-property-decorator";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          name: this.$route.params.preferredUsername,
        };
      },
      skip() {
        return !this.$route.params.preferredUsername;
      },
    },
    person: {
      query: PERSON_MEMBERSHIPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
        };
      },
      skip() {
        return !this.currentActor || !this.currentActor.id;
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class GroupMixin extends Vue {
  group: IGroup = new Group();
  currentActor!: IActor;

  person!: IPerson;

  get isCurrentActorAGroupAdmin(): boolean {
    return (
      this.person &&
      this.person.memberships.elements.some(
        ({ parent: { id }, role }) => id === this.group.id && role === MemberRole.ADMINISTRATOR
      )
    );
  }
}