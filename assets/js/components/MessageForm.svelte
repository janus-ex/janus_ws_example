<script>
  import { createEventDispatcher } from "svelte";

  const dispatch = createEventDispatcher();

  export let name = "";
  export let content = "";
  export let submitEnabled;

  function handleSubmit(event) {
    if (content.trim() !== "") {
      dispatch("submit", { name, content });
    }
  }
</script>

<div class="max-w-md">
  <label class="text-sm font-bold block mb-2" for="message_name">
    Name
    <span class="font-normal text-gray-600">(optional)</span>
  </label>
  <input
    aria-describedby="name-desc"
    class="border border-gray-400 p-2 mb-2 block w-full"
    id="message_name"
    name="message[name]"
    type="text"
    bind:value={name} />
</div>

<div>
  <label class="text-sm font-bold block mb-2" for="message_content">
    Message
  </label>
  <textarea
    aria-describedby="comment-desc"
    class="block w-full border border-gray-400 p-2 mb-2"
    id="message_content"
    name="message[content]"
    placeholder="Type your message here ..."
    bind:value={content} />
</div>

<!-- TODO I'd rather have on:submit instead of on:click -->

<div class="mt-3">
  <button
    class="font-bold px-3 py-2 w-full border border-gray-400 pointer"
    type="submit"
    on:click|preventDefault={handleSubmit}>
    SEND IT
  </button>
</div>
