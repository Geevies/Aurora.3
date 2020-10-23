<template>
  <div>
    <div class="row">
      <div class="column">
        <div class="phoroncount"><vui-tooltip :label="roundValue(phoron_count)">{{ phoron_count }}</vui-tooltip> Sheets<br><span style="font-size:75%">{{ per_second }} p/s</span></div>
        <img @click="clicked()" class="phoronimage" src="phoron.png">
      </div>
      <div class="column">
        <h3>Placeholder</h3>
      </div>
      <div class="column">
        <h3>Upgrades</h3>
      </div>
    </div>
    <p class="fineprint">Phoron Clicker is a complex calculation engine, every phoron sheet obtained solves complex research calculation proposed by NanoTrasen research departments across Orion Spur space. NanoTrasen reaps 100% of the credit bounties put out to solve these, if they are solved using this program. However, to whomever's CPU is used to run it on, a sense of satisfaction is given in the form of numbers increasing.</p>
  </div>
</template>

<script>
export default {
  data() {
    return this.$root.$data.state;
  },
  methods: {
    clicked() {
      this.$root.$data.state.phoron_count++;
    },
    roundValue(value) {
      return value.toFixed(2)
    }
  }
}
</script>

<style lang="scss" scoped>
.column {
  float: left;
  width: 32%;
  margin-left: 1%;
  outline-style: ridge;
  outline-color: black;
  background-color: rgba(0, 0, 0, 0.4);
  height: 400px;
  overflow: auto;
}

.column .phoroncount {
  vertical-align: middle;
  text-align: center;
  height: 20%;
  width: 90%;
  margin-top: 10px;
  margin-left: 5%;
  padding: 25px, 25px;
  outline-style: outset;
  outline-color: purple;
  outline-width: 50%;
  background-color: rgba(150, 20, 255, 0.5);
  color: rgb(0, 255, 180);
  font-family: sans-serif;
  font-size: 200%;
  overflow: hidden;
}

.column .phoronimage {
  display: block;
  margin-left: auto;
  margin-right: auto;
  width: auto;
  height : auto;
  max-height: 100%;
  max-width: 100%;
}

.column h3 {
  text-align: center;
}

.fineprint {
  font-size: 15%;
}

/* Clear floats after the columns */
.row:after {
  content:"";
  display: table;
  clear: both;
}
</style>