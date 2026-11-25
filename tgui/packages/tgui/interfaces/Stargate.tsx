import { useState } from 'react';
import {
  Box,
  Button,
  Image,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type StargateData = {
  address?: string | null;
  anchored?: BooleanLike;
  charging?: BooleanLike;
  deployable?: BooleanLike;
  destination?: string | null;
  enabled?: BooleanLike;
  has_ring: BooleanLike;
  linked?: BooleanLike;
  max_length: number;
  powered?: BooleanLike;
  ring_images: { idle: string; linked: string };
};

export function Stargate() {
  const { act, data } = useBackend<StargateData>();
  const {
    address,
    anchored,
    charging,
    deployable,
    destination,
    enabled,
    has_ring,
    linked,
    powered,
    ring_images,
  } = data;
  const accent = linked ? '#73e4d6' : charging ? '#9edff9' : '#e9bd79';
  let status = 'Awaiting remote activation';
  if (!has_ring) {
    status = 'No ring connected';
  } else if (linked) {
    status = 'Passage open';
  } else if (charging) {
    status = 'Charging both rings';
  } else if (deployable) {
    if (!anchored) {
      status = 'Anchor the ring';
    } else if (!powered) {
      status = 'No equipment power';
    } else if (!address) {
      status = 'Set a gate address';
    } else if (!enabled) {
      status = 'Ready to activate';
    }
  } else {
    status = 'Awaiting a match';
  }

  return (
    <Window width={420} height={deployable ? 350 : 246}>
      <Window.Content scrollable>
        <Box
          mb={1}
          p={1}
          style={{
            background: 'linear-gradient(100deg, #13272d, #192027)',
            borderLeft: `3px solid ${accent}`,
          }}
        >
          <Stack align="center">
            <Stack.Item>
              <Image
                width="120px"
                height="48px"
                src={`data:image/png;base64,${linked ? ring_images.linked : ring_images.idle}`}
              />
            </Stack.Item>
            <Stack.Item grow minWidth={0}>
              <Box bold color={accent} fontSize={1.25}>
                {status}
              </Box>
              <Box mt={0.25} style={{ overflowWrap: 'anywhere' }}>
                {linked || charging
                  ? destination || 'Remote gate'
                  : address || 'No address configured'}
              </Box>
            </Stack.Item>
          </Stack>
        </Box>
        {has_ring ? (
          <>
            <AddressEditor key={address} />
            {!!deployable && <ActivationPanel />}
            <Button
              color="transparent"
              icon="unlink"
              onClick={() => act('unlink_ring')}
            >
              Disconnect ring
            </Button>
          </>
        ) : (
          <Section title="Connect a ring">
            Scan a stargate with a multitool, then use the multitool on this
            computer.
          </Section>
        )}
      </Window.Content>
    </Window>
  );
}

function ActivationPanel() {
  const { act, data } = useBackend<StargateData>();
  const { address, anchored, charging, enabled, linked, powered } = data;
  const disabled = !enabled && (!address || !anchored || !powered);
  const action = enabled
    ? linked
      ? 'Close passage'
      : charging
        ? 'Cancel charge'
        : 'Disarm ring'
    : 'Activate ring';

  return (
    <Section title="Activation">
      <Box
        p={1}
        style={{
          background: 'linear-gradient(#22282e, #12171c)',
          border: '1px solid #4b5459',
          borderRadius: '6px',
          boxShadow: 'inset 0 1px #ffffff18',
        }}
      >
        <Stack align="center">
          <Stack.Item mr={1.5}>
            <button
              type="button"
              aria-label={action}
              aria-pressed={!!enabled}
              disabled={disabled}
              onClick={() => act('set_activation', { enabled: !enabled })}
              style={{
                width: '62px',
                height: '48px',
                border: '4px solid #68737a',
                borderRadius: '32px',
                color: enabled ? '#ffe6ce' : '#24170d',
                background: enabled
                  ? 'linear-gradient(#802c28, #bb4331)'
                  : 'linear-gradient(#ffcc78, #c06a2b)',
                boxShadow: enabled
                  ? '0 0 0 2px #101418, inset 0 3px 6px #421a16'
                  : '0 3px #0c0f12, inset 0 1px 2px #fff2ba',
                cursor: disabled ? 'default' : 'pointer',
                opacity: disabled ? 0.5 : 1,
                fontSize: '18px',
                fontWeight: 700,
              }}
            >
              ⏻
            </button>
          </Stack.Item>
          <Stack.Item grow>
            <Box bold>{action}</Box>
            <Box color="label">
              Both rings must be activated to start the charge.
            </Box>
          </Stack.Item>
        </Stack>
      </Box>
    </Section>
  );
}

function AddressEditor() {
  const { act, data } = useBackend<StargateData>();
  const { address, charging, linked, max_length } = data;
  const [draft, setDraft] = useState(address ?? '');
  const nextAddress = draft.trim();
  const changed = !!nextAddress && nextAddress !== address;

  function save() {
    if (changed) {
      act('set_address', {
        address: nextAddress,
        previous_address: address ?? null,
      });
    }
  }

  return (
    <Section title="Gate address">
      <Box mb={1}>
        Set both gates to the same address, including capitalization.
      </Box>
      <Stack align="center">
        <Stack.Item grow>
          <Input
            aria-label="Gate address"
            autoSelect
            fluid
            maxLength={max_length}
            monospace
            onChange={setDraft}
            onEnter={save}
            placeholder="e.g. North Outpost"
            value={draft}
          />
        </Stack.Item>
        <Stack.Item>
          <Button color="teal" disabled={!changed} icon="check" onClick={save}>
            Apply
          </Button>
        </Stack.Item>
      </Stack>
      {!!(linked || charging) && changed && (
        <Box color="average" mt={1}>
          {charging
            ? 'Applying this address will cancel the charge.'
            : 'Applying this address will close the current passage.'}
        </Box>
      )}
    </Section>
  );
}
