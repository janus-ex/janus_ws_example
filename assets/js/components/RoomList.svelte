<script>
  import RoomListItem from "./RoomListItem.svelte";

  export let rooms;
</script>

<ul>
  {#each rooms as room}
    <RoomListItem {room} />
  {:else}
    <!-- TODO and in html.eex as well -->
    <li class="pa3 pa4-ns">No rooms</li>
  {/each}
</ul>
