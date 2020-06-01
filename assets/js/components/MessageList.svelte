<script>
  import MessageListItem from "./MessageListItem.svelte";

  export let messages;
</script>

<ul>
  {#each messages as message}
    <MessageListItem {message} />
  {/each}
</ul>
