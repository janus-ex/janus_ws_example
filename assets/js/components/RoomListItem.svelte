<script>
  export let room;
</script>

<li class="p-3 border-b">
  <a href="/{room.name}" class="text-3xl block mb-1 font-bold underline italic">
    {room.name}
  </a>
  <span class="block max-w-md">
    {#if room.lastMessage}
      <strong>{room.lastMessage.author}</strong>
      {room.lastMessage.content}
    {:else}No messages{/if}
  </span>
</li>
