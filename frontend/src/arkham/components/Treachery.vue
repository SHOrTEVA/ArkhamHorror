<script lang="ts" setup>
import { computed } from 'vue';
import { useDebug } from '@/arkham/debug';
import { imgsrc } from '@/arkham/helpers';
import type { Game } from '@/arkham/types/Game';
import { TokenType } from '@/arkham/types/Token';
import * as ArkhamGame from '@/arkham/types/Game';
import type { AbilityLabel, AbilityMessage, Message } from '@/arkham/types/Message';
import PoolItem from '@/arkham/components/PoolItem.vue';
import AbilityButton from '@/arkham/components/AbilityButton.vue'
import Token from '@/arkham/components/Token.vue';
import * as Arkham from '@/arkham/types/Treachery';

export interface Props {
  game: Game
  treachery: Arkham.Treachery
  playerId: string
  attached?: boolean
  overlayDelay?: number
}

const props = withDefaults(defineProps<Props>(), { attached: false })

const emits = defineEmits<{ choose: [value: number] }>()

const choose = (idx: number) => emits('choose', idx)

const debug = useDebug()
const image = computed(() => {
  return imgsrc(`cards/${props.treachery.cardCode.replace('c', '')}.avif`)
})
const id = computed(() => props.treachery.id)
const choices = computed(() => ArkhamGame.choices(props.game, props.playerId))
const isExhausted = computed(() => props.treachery.exhausted)

function canInteract(c: Message): boolean {
  if (c.tag === "TargetLabel") {
    return c.target.contents === id.value || `c${id.value}` === c.target.contents || c.target.contents == props.treachery.cardId
  }

  return false
}

function isAbility(v: Message): v is AbilityLabel {
  if (v.tag !== 'AbilityLabel') {
    return false
  }

  const { source } = v.ability;

  if (source.sourceTag === 'ProxySource') {
    if ("contents" in source.source) {
      return source.source.contents === id.value
    }
  } else if (source.tag === 'TreacherySource') {
    return source.contents === id.value
  }

  return false
}

const abilities = computed(() => {
  return choices
    .value
    .reduce<AbilityMessage[]>((acc, v, i) => {
      if (isAbility(v)) {
        return [...acc, { contents: v, displayAsAction: false, index: i }];
      }

      return acc;
    }, []);
})

const doom = computed(() => props.treachery.tokens[TokenType.Doom])
const clues = computed(() => props.treachery.tokens[TokenType.Clue])
const resources = computed(() => props.treachery.tokens[TokenType.Resource])
const charges = computed(() => props.treachery.tokens[TokenType.Charge])
const horror = computed(() => props.treachery.tokens[TokenType.Horror])
const evidence = computed(() => props.treachery.tokens[TokenType.Evidence])

const cardAction = computed(() => choices.value.findIndex(canInteract))
</script>
<template>
  <div class="treachery" :class="{ attached, exhausted: isExhausted }">
    <img
      :src="image"
      class="card"
      :class="{ 'treachery--can-interact': cardAction !== -1, attached }"
      @click="$emit('choose', cardAction)"
      :data-delay="overlayDelay"
    />
    <AbilityButton
      v-for="ability in abilities"
      :key="ability.index"
      :ability="ability.contents"
      :data-image="image"
      :game="game"
      @click="$emit('choose', ability.index)"
      />
    <div class="pool">
      <PoolItem
        v-if="horror && horror > 0"
        type="horror"
        :amount="horror"
      />
      <PoolItem
        v-if="clues && clues > 0"
        type="clue"
        :amount="clues"
      />
      <PoolItem
        v-if="resources && resources > 0"
        type="resource"
        :amount="resources"
      />
      <PoolItem
        v-if="charges && charges > 0"
        type="resource"
        :amount="charges"
      />
      <PoolItem
        v-if="doom && doom > 0"
        type="doom"
        :amount="doom"
      />
      <PoolItem v-if="evidence && evidence > 0" type="resource" tooltip="Evidence" :amount="evidence" />
      <Token v-for="(sealedToken, index) in treachery.sealedChaosTokens" :key="index" :token="sealedToken" :playerId="playerId" :game="game" @choose="choose" />
    </div>

    <template v-if="debug.active">
      <button @click="debug.send(game.id, {tag: 'Discard', contents: [null, { tag: 'GameSource' }, { tag: 'TreacheryTarget', contents: id}]})">Discard</button>
    </template>
  </div>
</template>


<style lang="scss" scoped>
.card {
  width: var(--card-width);
  max-width: var(--card-width);
  border-radius: 5px;
}

.treachery--can-interact {
  border: 2px solid var(--select);
  cursor:pointer;
}

.treachery {
  display: flex;
  flex-direction: column;
  position: relative;
  width: fit-content;
}

.attached .card {
  object-fit: cover;
  object-position: left bottom;
  height: calc(var(--card-width) * 0.6);
}

.pool {
  position: absolute;
  top: 10%;
  align-items: center;
  display: flex;
  align-self: flex-start;
  align-items: flex-end;
  flex-wrap: wrap;
  :deep(.token-container) {
    width: unset;
  }
  :deep(img) {
    width: 20px;
    height: auto;
  }


  pointer-events: none;
}

.exhausted {
  :deep(img) {
    transition: transform 0.2s linear;
    transform: rotate(90deg) translateX(-10px);
  }
}
</style>
