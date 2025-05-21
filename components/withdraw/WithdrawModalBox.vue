<template>
  <div class="modal-card box box-modal">
    <header class="box-modal-header is-spaced">
      <div class="box-modal-title">{{ $t('withdrawalConfirmation') }}</div>
      <button type="button" class="delete" @click="$emit('close')" />
    </header>
    <div class="note" data-test="withdrawal_confirmation_text">
      {{ $t('yourZkSnarkProofHasBeenSuccesfullyGenerated') }}
    </div>
    <b-button type="is-primary is-fullwidth" data-test="withdrawal_confirm_button" @click="_sendWithdraw">
      {{ $t('confirm') }}
    </b-button>
  </div>
</template>
<script>
/* eslint-disable no-console */

export default {
  props: {
    note: {
      type: String,
      required: true
    },
    withdrawType: {
      type: String,
      required: true
    }
  },
  computed: {
    withdrawalMethod() {
      if (this.withdrawType === 'wallet') {
        return 'application/withdraw'
      }

      // NOTE: replaced normal relayer withdrawal with innocence endpoint call
      return 'relayer/relayTornadoInnocentWithdraw'
    }
  },

  methods: {
    async _sendWithdraw() {
      this.$store.dispatch('loading/enable', { message: this.$t('preparingTransactionData') })

      try {
        const txHash = await this.$store.dispatch(this.withdrawalMethod, {
          note: this.note
        })

        if (this.withdrawType === 'wallet') {
          const [torn, currency, amount] = this.note.split('-')
          console.log('torn:', torn, 'currency:', currency, 'amount:', amount)

          if (!currency) {
            console.warn('Currency is missing in note:', this.note)
          }

          this.$store.commit(
            'txHashKeeper/SAVE_TX_HASH',
            {
              txHash,
              prefix: `${currency}-${amount}`,
              note: this.note,
              currency,
              timestamp: Math.floor(Date.now() / 1000),
              status: 0,
              isSpent: false,
              storeType: 'txs'
            },
            { root: true }
          )

          this.$router.push('/')
        }

        this.$root.$emit('resetWithdraw')
      } catch (e) {
        console.error(e)
        this.$store.dispatch('notice/addNoticeWithInterval', {
          notice: {
            untranslatedTitle: e.message,
            type: 'danger'
          },
          interval: 3000
        })
      } finally {
        this.$store.dispatch('loading/disable')
        this.$parent.close()
      }
    }
  }
}
</script>
