<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.balanceCard">
        <svg
            :class="$style.balanceWaves"
            viewBox="0 0 900 600"
            preserveAspectRatio="none"
            aria-hidden="true"
            focusable="false"
            xmlns="http://www.w3.org/2000/svg">
            <path d="M0 206L18.8 225.7C37.7 245.3 75.3 284.7 112.8 299.3C150.3 314 187.7 304 225.2 305.2C262.7 306.3 300.3 318.7 337.8 324.2C375.3 329.7 412.7 328.3 450.2 305.8C487.7 283.3 525.3 239.7 562.8 227.7C600.3 215.7 637.7 235.3 675.2 255.2C712.7 275 750.3 295 787.8 290.7C825.3 286.3 862.7 257.7 881.3 243.3L900 229L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-1)" />
            <path d="M0 307L18.8 305.3C37.7 303.7 75.3 300.3 112.8 309.2C150.3 318 187.7 339 225.2 352.7C262.7 366.3 300.3 372.7 337.8 374.3C375.3 376 412.7 373 450.2 353C487.7 333 525.3 296 562.8 291.7C600.3 287.3 637.7 315.7 675.2 328.5C712.7 341.3 750.3 338.7 787.8 328.8C825.3 319 862.7 302 881.3 293.5L900 285L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-2)" />
            <path d="M0 346L18.8 348.7C37.7 351.3 75.3 356.7 112.8 354.3C150.3 352 187.7 342 225.2 350.3C262.7 358.7 300.3 385.3 337.8 392.8C375.3 400.3 412.7 388.7 450.2 373.2C487.7 357.7 525.3 338.3 562.8 329C600.3 319.7 637.7 320.3 675.2 317.3C712.7 314.3 750.3 307.7 787.8 304.8C825.3 302 862.7 303 881.3 303.5L900 304L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-3)" />
            <path d="M0 388L18.8 393.3C37.7 398.7 75.3 409.3 112.8 417.2C150.3 425 187.7 430 225.2 419C262.7 408 300.3 381 337.8 373.7C375.3 366.3 412.7 378.7 450.2 387.3C487.7 396 525.3 401 562.8 404C600.3 407 637.7 408 675.2 410.2C712.7 412.3 750.3 415.7 787.8 423.5C825.3 431.3 862.7 443.7 881.3 449.8L900 456L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-4)" />
            <path d="M0 440L18.8 439.8C37.7 439.7 75.3 439.3 112.8 442.7C150.3 446 187.7 453 225.2 454.3C262.7 455.7 300.3 451.3 337.8 444C375.3 436.7 412.7 426.3 450.2 429.8C487.7 433.3 525.3 450.7 562.8 462C600.3 473.3 637.7 478.7 675.2 477.8C712.7 477 750.3 470 787.8 468.8C825.3 467.7 862.7 472.3 881.3 474.7L900 477L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-5)" />
            <path d="M0 470L18.8 469.3C37.7 468.7 75.3 467.3 112.8 469.8C150.3 472.3 187.7 478.7 225.2 485C262.7 491.3 300.3 497.7 337.8 503.2C375.3 508.7 412.7 513.3 450.2 512.8C487.7 512.3 525.3 506.7 562.8 506.5C600.3 506.3 637.7 511.7 675.2 504.7C712.7 497.7 750.3 478.3 787.8 469.8C825.3 461.3 862.7 463.7 881.3 464.8L900 466L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-6)" />
            <path d="M0 542L18.8 542C37.7 542 75.3 542 112.8 537.2C150.3 532.3 187.7 522.7 225.2 520.5C262.7 518.3 300.3 523.7 337.8 529.7C375.3 535.7 412.7 542.3 450.2 545.2C487.7 548 525.3 547 562.8 544.8C600.3 542.7 637.7 539.3 675.2 534.3C712.7 529.3 750.3 522.7 787.8 518.7C825.3 514.7 862.7 513.3 881.3 512.7L900 512L900 601L881.3 601C862.7 601 825.3 601 787.8 601C750.3 601 712.7 601 675.2 601C637.7 601 600.3 601 562.8 601C525.3 601 487.7 601 450.2 601C412.7 601 375.3 601 337.8 601C300.3 601 262.7 601 225.2 601C187.7 601 150.3 601 112.8 601C75.3 601 37.7 601 18.8 601L0 601Z" fill="var(--balance-wave-7)" />
        </svg>

        <div :class="$style.balanceContent">
            <p :class="$style.balanceKicker">Ваш абонемент</p>
            <p :class="$style.balanceNumber">{{ state.studentUser.lessonsLeft }} {{ humanCount(state.studentUser.lessonsLeft, 'занятие', 'занятия', 'занятий') }}</p>
            <p :class="$style.balanceCaption">Осталось оплаченных уроков</p>

            <div :class="$style.buttonRow">
                <AppButton
                    variant="white"
                    @click="openPayment"
                >
                <svg>
                    <use href="#icon-wallet" />
                </svg>
                &#32;&#32;Оплатить абонемент&#32;
                </AppButton>
            </div>
        </div>
        <span :class="$style.balanceMark">
            <svg>
                <use href="#icon-cap" />
            </svg>
        </span>
    </section>
</template>

<style lang="scss" module>
.balanceCard {
    --balance-wave-1: #26378e;
    --balance-wave-2: #3b54a3;
    --balance-wave-3: #5271b7;
    --balance-wave-4: #6d8eca;
    --balance-wave-5: #8babdb;
    --balance-wave-6: #acc9ec;
    --balance-wave-7: #e2f3ff;

    position: relative;
    overflow: hidden;
    display: flex;
    justify-content: space-between;
    gap: 18px;
    min-height: 239px;
    padding: 24px;
    border-radius: $radius;
    color: var(--on-purple-pale);
    background: linear-gradient(118deg, var(--purple-dark) 0%, var(--purple) 52%, var(--purple) 100%);
}

.balanceWaves {
    position: absolute;
    inset: 0;
    z-index: 0;
    display: block;
    width: 100%;
    height: 100%;
    pointer-events: none;
}

[data-theme='darked'] {
    .balanceCard {
        --balance-wave-1: #082052;
        --balance-wave-2: #0b2e68;
        --balance-wave-3: #12417f;
        --balance-wave-4: #215a99;
        --balance-wave-5: #417bb6;
        --balance-wave-6: #76a2d1;
        --balance-wave-7: #e2f3ff;

        color: var(--ink);
        background: linear-gradient(118deg, #10244d 0%, #183c69 52%, #1b4778 100%);
    }

    .balanceKicker,
    .balanceCaption {
        color: color-mix(in srgb, var(--ink) 78%, transparent);
    }

    .balanceMark {
        border-color: color-mix(in srgb, var(--ink) 30%, transparent);
        background: color-mix(in srgb, var(--ink) 16%, transparent);

        svg {
            stroke: var(--ink);
        }
    }
}

.balanceContent {
    position: relative;
    z-index: 1;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    width: 100%;

    button[data-variant=white] {
        background: transparent !important;
        border: 1px solid var(--ink);
        backdrop-filter: blur(3px);
    }
}
.balanceKicker {
    margin: 0 0 17px;
    color: color-mix(in srgb, var(--on-purple-pale) 76%, transparent);

    @include text(px2);
}
.balanceNumber {
    margin: 0;
    font: 700 43px/1 "Montserrat", sans-serif;
    letter-spacing: -1.5px;
}
.balanceCaption {
    margin: 7px 0 20px;
    color: color-mix(in srgb, var(--on-purple-pale) 78%, transparent);
    font-size: 12px;
}
.balanceMark {
    position: absolute;
    top: $padding;
    right: $padding;
    z-index: 1;
    align-self: flex-start;
    width: $width-block;
    min-width: $width-block;
    height: $height-block;
    display: grid;
    place-items: center;
    border: 1px solid rgba($white, 0.3);
    border-radius: $radius-mini;
    background: rgba($white, 0.24);

    @include respond-to(mobile) {
        top: $padding-mobile;
        right: $padding-mobile;
    }

    svg {
        width: $svg;
        height: $svg;
        stroke: $white;
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
}

.buttonRow {
    position: relative;
    z-index: 1;
    display: flex;
    gap: 9px;
    flex-flow: row nowrap;
    font-size: 12px;

    button {
        width: 100%;
        padding: 4px 8px;
        gap: 4px;
        font-size: 16px !important;
        font-weight: 300;
        border-radius: $radius-mini;

        @include respond-to(mobile) {
            font-size: 12px !important;
            font-weight: 700;
        }

        svg {
            width: calc($svg - 6px);
            height: calc($svg - 6px);
            stroke: currentColor;
            fill: none;
            stroke-width: 1.7;
        }
    }

    svg {
        width: $svg;
        height: $svg;
        stroke: currentColor;
        fill: none;
    }
}
@include respond-to(mobile) {
    .balanceCard {
        min-height: 184px;
        padding: 16px;
    }
    .balanceNumber {
        font-size: 38px;
    }
}
</style>
