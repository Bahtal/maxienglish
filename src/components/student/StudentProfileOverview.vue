<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VAvatar from '../VAvatar.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VAvatar },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.profileOverview">
        <div :class="$style.profileIdentity">
            <VAvatar
                :class="$style.avatar"
                size="large"
                radius="default"
                :src="state.studentUser.avatarUrl"
                :name="state.studentUser.name"
            />
            <div>
                <h2>{{ state.studentUser.name }}</h2>
                <p
                    :class="$style.profileTelegram">{{ selectedStudent?.username ? `@${selectedStudent.username}` : 'Ученик' }}</p>
            </div>
        </div>
        <div :class="[$style.detailStats, $style.profilePageStats]">
            <div :class="$style.detailStat">
                <b>{{ state.studentUser.lessonsLeft }}</b>
                <small>уроков осталось</small>
            </div>
            <div :class="$style.detailStat">
                <b>{{ selectedStudent?.attendance?.length || 0 }}</b>
                <small>уроков пройдено</small>
            </div>
            <div :class="$style.detailStat">
                <b>{{ studentHomework.filter(isDoneHomework).length }}</b>
                <small>заданий выполнено</small>
            </div>
        </div>
    </section>
</template>

<style lang="scss" module>
.avatar {
    font-size: 17px;
    font-weight: 100;
}

.eyebrow {
    color: var(--ink);
    letter-spacing: 0.5px;
    font-weight: 400;
    margin: 0;

    @include text(px3);
}

.miniProgress {
    margin-top: 8px;
    padding: 15px 0;
}

.miniProgressHead {
    display: flex;
    justify-content: space-between;
    color: var(--muted);
    font-size: 10px;

    b {
        color: var(--ink);
    }
}

.progressTrack {
    height: 6px;
    margin-top: 10px;
    border-radius: 8px;
    overflow: hidden;
    background: var(--line);
}

.progressFill {
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(90deg, var(--purple-dark), var(--purple));
}

.profileOverview {
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.profileIdentity {
    display: flex;
    align-items: center;
    gap: $gap;
    min-width: 0;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.profileIdentity {
    h2 {
        margin: 0;
        font-size: 16px;
    }
}

.profileTelegram {
    margin: 0;
    color: var(--muted);

    @include text(px3);
}

.profilePageStats {
    margin: 16px 0 0;
}

.profileOverview {
    .miniProgress {
        margin-top: 16px;
    }
}

.profilePaymentSummary {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    padding: 16px 0 0;
    color: var(--muted);
    font-size: 12px;

    b {
        color: var(--ink);
        font-weight: 700;
    }
}

.detailStats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 9px;
    margin: 16px 0 0;
}

.detailStat {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 12px 10px;
    box-shadow: $board-shadow;
    border-radius: $radius;

    b {
        display: block;
        font-weight: 700;

        @include text(px2);
    }

    small {
        display: block;
        margin-top: 5px;
        color: var(--muted);

        @include text(px2);
    }
}

@include respond-to(mobile) {
    .detailStats {
        gap: 4px;
    }

    .detailStat {
        padding: 10px 8px;

        b {
            font-size: 15px;
        }

        small {
            font-size: 8px;
        }
    }
}

@media (max-width: 360px) {
    .detailStat {
        padding: 8px 10px;

        b {
            font-size: 12px;
        }

        small {
            font-size: 8px;
        }
    }
}

[data-theme=darked] {
    .detailStat {
        color: var(--ink);
    }

    .profilePaymentSummary {
        color: var(--ink);

        b {
            color: var(--ink);
        }
    }

    .detailStat {
        b {
            color: var(--ink);
        }

        small {
            color: var(--muted);
        }
    }

    .progressTrack {
        background-color: var(--line);
    }

    .miniProgressHead {
        color: var(--muted);
    }
}
</style>
