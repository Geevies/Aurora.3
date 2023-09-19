import { useBackend } from '../backend';
import { Box, Divider, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export type ArmorValuesData = {
  armor_values: string[];
};

export const ArmorValues = (props, context) => {
  const { act, data } = useBackend<ArmorValuesData>(context);

  return (
    <Window resizable>
      <Window.Content scrollable>
        <Section>
          <Box>
            THE STATISTICS BELOW IS OUT OF CHARACTER INFO, YOU CAN USE THIS TO
            REFERENCE ARMOR VALUES, BUT DO NOT STATE THE PERCENTAGES IN
            CHARACTER
          </Box>
          <Divider />
          {Object.keys(data.armor_values).map((line) =>
            line ? (
              <Box>
                <Box pb={1}>{line.toUpperCase()}</Box>
                <ProgressBar
                  ranges={{
                    good: [50, 100],
                    average: [30, 50],
                    bad: [0, 30],
                  }}
                  value={data.armor_values[line]}
                  minValue={0}
                  maxValue={100}
                />
                <Divider />
              </Box>
            ) : null
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
