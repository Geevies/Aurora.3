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
  address: string | null;
  anchored?: BooleanLike;
  charging: BooleanLike;
  deployable?: BooleanLike;
  destination: string | null;
  enabled?: BooleanLike;
  linked: BooleanLike;
  max_length: number;
  powered?: BooleanLike;
  ring_images: { idle: string; linked: string };
};

export function Stargate() {
  const { data } = useBackend<StargateData>();
  const {
    address,
    anchored,
    charging,
    deployable,
    destination,
    enabled,
    linked,
    powered,
    ring_images,
  } = data;
  const accent = linked ? '#73e4d6' : charging ? '#9edff9' : '#e9bd79';
  let status = 'Awaiting the remote lever';
  if (linked) {
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
      status = 'Activation lever ready';
    }
  } else {
    status = 'Awaiting a match';
  }

  return (
    <Window width={420} height={deployable ? 300 : 246}>
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
        <AddressEditor key={address} />
        {!!deployable && (
          <Section title="Activation">
            <Box>
              {anchored
                ? 'Pull the physical lever beside each ring to start the charge.'
                : 'Secure the ring to a clear three-by-three floor with a wrench.'}
            </Box>
          </Section>
        )}
      </Window.Content>
    </Window>
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
      act('set_address', { address: nextAddress, previous_address: address });
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
