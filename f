import * as React from "react";
import PhoneInput from "react-phone-number-input";
import type { E164Number } from "libphonenumber-js/core";
import { Button } from "@fluentui/react-components";
import { Call24Regular } from "@fluentui/react-icons";
import "./css/PhoneFormatter.css";
import { IInputs } from "./generated/ManifestTypes";

interface Props {
  value: string;
  onValueChange: (e164: string) => void;
  disabled: boolean;
  required: boolean;
  context: ComponentFramework.Context<IInputs>;
  regardingId: string;
  regardingType: string;
  regardingName: string;
}

export default function PhoneInputt({ value, onValueChange, disabled, required, context, regardingId, regardingType, regardingName }: Props) {
  const trimmed = (value ?? "").trim();
  const canCall = trimmed.length > 0;
  const isNorthAmerican = trimmed.startsWith("+1") || !trimmed.startsWith("+");

  // Ref always holds latest regardingName regardless of when closure was created
  const regardingNameRef = React.useRef(regardingName);
  React.useEffect(() => {
    regardingNameRef.current = regardingName;
  }, [regardingName]);

  const e164Value = trimmed.startsWith("+")
    ? (trimmed as E164Number)
    : trimmed.length > 0
    ? (`+1${trimmed.replace(/\D/g, "")}` as E164Number)
    : undefined;

  const onCallClick = React.useCallback(
    (e: React.MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();
      if (!canCall) return;

      const name = regardingNameRef.current;  // ← always latest value

      context.navigation.openForm(
        { entityName: "phonecall" },
        {
          phonenumber:       trimmed,
          directioncode:     "1",
          regardingobjectid: {
            id:         regardingId,
            name:       name,
            entityType: regardingType,
          } as unknown as string,
          from: [
            {
              id:                    context.userSettings.userId,
              name:                  context.userSettings.userName,
              entityType:            "systemuser",
              participationtypemask: 1,
            },
          ] as unknown as string,
          to: [
            {
              id:                    regardingId,
              name:                  name,
              entityType:            regardingType,
              participationtypemask: 2,
            },
          ] as unknown as string,
        }
      );

      window.location.href = `tel:${trimmed}`;
    },
    [canCall, trimmed, context, regardingId, regardingType]  // ref doesn't need to be a dep
  );

  return (
    <div
      className={[
        "crm-phone-shell",
        disabled ? "crm-disabled" : "",
        required ? "crm-required" : "",
      ].join(" ")}
    >
      <div className="crm-phone-inputArea">
        <PhoneInput
          {...(isNorthAmerican ? { countries: ["CA", "US"] } : {})}
          defaultCountry="CA"
          international={!isNorthAmerican}
          countryCallingCodeEditable={false}
          value={e164Value}
          onChange={(num?: E164Number) => onValueChange(num ?? "")}
          disabled={disabled}
        />
      </div>

      <div className="crm-phone-actionArea">
        <Button
          className="crm-call-btn"
          appearance="subtle"
          icon={<Call24Regular />}
          disabled={!canCall}
          title="Call"
          aria-label="Call"
          onClick={onCallClick}
        />
      </div>
    </div>
  );
}
