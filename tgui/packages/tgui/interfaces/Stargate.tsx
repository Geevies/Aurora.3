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
  destination: string | null;
  linked: BooleanLike;
  max_length: number;
  ring_images: { idle: string; linked: string };
};

export function Stargate() {
  const { data } = useBackend<StargateData>();
  const { address, linked, destination, ring_images } = data;
  const accent = linked ? '#73e4d6' : '#e9bd79';

  return (
    <Window width={420} height={246}>
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
                {linked ? 'Passage open' : 'Awaiting a match'}
              </Box>
              <Box mt={0.25} style={{ overflowWrap: 'anywhere' }}>
                {linked
                  ? destination || 'Remote gate'
                  : address || 'Set a gate address'}
              </Box>
            </Stack.Item>
          </Stack>
        </Box>
        <AddressEditor key={address} />
      </Window.Content>
    </Window>
  );
}

function AddressEditor() {
  const { act, data } = useBackend<StargateData>();
  const { address, linked, max_length } = data;
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
      {!!linked && changed && (
        <Box color="average" mt={1}>
          Applying this address will close the current passage.
        </Box>
      )}
    </Section>
  );
}
