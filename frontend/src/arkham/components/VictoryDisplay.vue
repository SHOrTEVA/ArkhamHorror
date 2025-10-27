<script lang="ts" setup>
import { computed } from 'vue';
import type { Game } from '@/arkham/types/Game';
import type { Card } from '@/arkham/types/Card';
import CardView from '@/arkham/components/Card.vue'
import Enemy from '@/arkham/components/Enemy.vue';
import { pluralize } from '@/arkham/helpers';
import { useI18n } from 'vue-i18n';
import { IsMobile } from '@/arkham/isMobile';
const { t } = useI18n();

export interface Props {
  game: Game
  playerId: string
  victoryDisplay: Card[]
}

const props = defineProps<Props>()
const emit = defineEmits(['show', 'choose'])

const choose = async (idx: number) => emit('choose', idx)

const enemiesInVictoryDisplay = computed(() => {
  return Object.values(props.game.enemies).filter((e) => e.placement.tag === 'OutOfPlay' && (['VictoryDisplayZone'] as string[]).includes(e.placement.contents))
})
const topOfVictoryDisplay = computed(() => {
  const enemyCardIds = enemiesInVictoryDisplay.value.map(e => e.cardId)
  return props.victoryDisplay.filter((c) => !enemyCardIds.includes(c.contents.id))[0]
})

const viewVictoryDisplayLabel = computed(() => pluralize(t('scenario.discardCard'), props.victoryDisplay.length))
const showVictoryDisplay = () => emit('show')
const { isMobile } = IsMobile();
</script>
i
<template>
  <div v-if="topOfVictoryDisplay || enemiesInVictoryDisplay.length > 0" class="victory-display" @click="showVictoryDisplay">
    <div v-if="topOfVictoryDisplay" class="victory-display-card">
      <CardView :game="game" :card="topOfVictoryDisplay" :playerId="playerId" />
      <span class="deck-size">{{props.victoryDisplay.length}}</span>
    </div>

    <Enemy
      v-for="enemy in enemiesInVictoryDisplay"
      :enemy="enemy"
      :game="game"
      :playerId="playerId"
      @choose="choose"
    />

    <button v-if="topOfVictoryDisplay && !isMobile" @click="showVictoryDisplay">{{viewVictoryDisplayLabel}}</button>
  </div>
</template>

<style scoped>
.card {
  width: 100px;
  border-radius: 6px;
  box-shadow: unset;
}

.victory-display {
  display: flex;
  flex-direction: column;
  gap: 5px;

  &:deep(.card-wrapper) {
    &::after {
      border-radius: 6px;
      pointer-events: none;
      content: "";
      position: absolute;
      inset: 0;
      background-color: #FFF;
      opacity: .85;
      mix-blend-mode: saturation;
      z-index: 20;
    }
  }
  &:deep(.card) {
    box-shadow: unset;
    margin: 0;
  }
}

.victory-display-card {
  position: relative;
  width: fit-content;
  line-height: 0;
  box-shadow: 1px 1px 6px rgba(0, 0, 0, 0.45);

  &::after {
    border-radius: 6px;
    pointer-events: none;
    content: "";
    position: absolute;
    inset: 0;
    background-color: #FFF;
    opacity: .85;
    mix-blend-mode: saturation;
  }
}

.deck-size {
  position: absolute;
  font-weight: bold;
  font-size: 1.2em;
  color: rgba(255, 255, 255, 1);
  left: 50%;
  bottom: 55%;
  transform: translateX(-50%) translateY(-50%);
  pointer-events: none;
  -webkit-text-stroke: 1px black;
}
</style>
