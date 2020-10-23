<template>
  <div>
    <h1 @click="clicked()">Click this!</h1>
    <p>Phoron Count: {{ phoron_count }}</p>
  </div>
</template>

<script>
export default {
  data() {
    return this.$root.$data.state;
  },
  methods: {
    clicked() {
      this.$root.$data.state.phoron_count++
    }
  }
}
</script>

<style lang="scss" scoped>
.column {
  float: left;
  width: 45%;
  margin: 1%;
  padding: 10px;
  outline-style: ridge;
  outline-color: black;
  background-color: rgba(0, 0, 0, 0.4);
  height: 500px;
  overflow: auto;
}

/* Clear floats after the columns */
.row:after {
  content:"";
  display: table;
  clear: both;
}
</style>