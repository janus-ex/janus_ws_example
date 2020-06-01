<script>
  export let message;
</script>

<li class="px-4 py-3 max-w-lg">
  <strong style="position:relative;right:0.66em;" class="uppercase italic">
    {message.author}
  </strong>
  {message.content}
</li>
